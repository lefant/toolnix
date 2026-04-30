import { Type } from "@sinclair/typebox";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

type RawOption = string | {
	label?: string;
	text?: string;
	title?: string;
	value?: string;
	description?: string;
};

type AskUserParams = {
	question: string;
	context?: string;
	options?: RawOption[];
	default?: string;
	allow_free_text?: boolean;
	allowFreeText?: boolean;
	multi_select?: boolean;
	multiSelect?: boolean;
};

type AskUserDetails = {
	question: string;
	options: string[];
	answer: string | string[] | null;
	cancelled: boolean;
	custom?: boolean;
};

const CUSTOM_OPTION = "Other — type a custom answer";

const AskUserParamsSchema = Type.Object({
	question: Type.String({ description: "Question to ask the user." }),
	context: Type.Optional(Type.String({ description: "Optional context shown with the question." })),
	options: Type.Optional(Type.Array(Type.Any(), { description: "Optional answer choices as strings or objects with label/text/title/value." })),
	default: Type.Optional(Type.String({ description: "Optional default free-text answer." })),
	allow_free_text: Type.Optional(Type.Boolean({ description: "Whether to offer a free-text answer option. Defaults to true." })),
	allowFreeText: Type.Optional(Type.Boolean({ description: "Camel-case alias for allow_free_text." })),
	multi_select: Type.Optional(Type.Boolean({ description: "Whether the user may select multiple options." })),
	multiSelect: Type.Optional(Type.Boolean({ description: "Camel-case alias for multi_select." })),
});

function optionLabel(option: RawOption): string {
	if (typeof option === "string") return option;
	if (!option || typeof option !== "object") return String(option);
	const label = option.label ?? option.text ?? option.title ?? option.value;
	return label === undefined ? JSON.stringify(option) : String(label);
}

function normalizeArgs(args: unknown): Record<string, unknown> {
	if (typeof args === "string") return { question: args };
	if (!args || typeof args !== "object") return { question: "How should the agent proceed?" };

	const normalized = { ...(args as Record<string, unknown>) };
	if (typeof normalized.question !== "string") {
		for (const key of ["prompt", "message", "title", "text"]) {
			if (typeof normalized[key] === "string") {
				normalized.question = normalized[key];
				break;
			}
		}
	}
	if (typeof normalized.question !== "string") {
		normalized.question = "How should the agent proceed?";
	}
	return normalized;
}

function questionText(params: AskUserParams): string {
	const context = params.context?.trim();
	return context ? `${params.question}\n\n${context}` : params.question;
}

function parseMultiAnswer(input: string, labels: string[]): string | string[] {
	const trimmed = input.trim();
	const parts = trimmed.split(/[\s,]+/).filter(Boolean);
	if (parts.length > 0 && parts.every((part) => /^\d+$/.test(part))) {
		const indices = parts.map((part) => Number(part) - 1);
		if (indices.every((index) => index >= 0 && index < labels.length)) {
			return indices.map((index) => labels[index]);
		}
	}
	return trimmed;
}

export default function askUserExtension(pi: ExtensionAPI): void {
	pi.registerTool({
		name: "ask_user",
		label: "Ask User",
		description: "Ask the user a blocking question and return their answer. Use when Compound Engineering skills require explicit user input before proceeding.",
		promptSnippet: "Ask the user a blocking question with optional choices and free-text fallback.",
		promptGuidelines: [
			"Use ask_user when a skill says to use Pi's platform blocking question tool.",
			"Use ask_user before making workflow decisions that require explicit user choice; do not silently choose for the user.",
		],
		parameters: AskUserParamsSchema,
		prepareArguments: normalizeArgs,

		async execute(_toolCallId, params: AskUserParams, _signal, _onUpdate, ctx) {
			const labels = (params.options ?? []).map(optionLabel).filter((label) => label.trim().length > 0);
			const allowFreeText = params.allow_free_text ?? params.allowFreeText ?? true;
			const multiSelect = params.multi_select ?? params.multiSelect ?? false;
			const prompt = questionText(params);

			if (!ctx.hasUI) {
				const optionsText = labels.length > 0 ? ` Options: ${labels.map((label, index) => `${index + 1}. ${label}`).join("; ")}` : "";
				return {
					content: [{ type: "text", text: `UI not available. Present this question in chat and wait for the user's reply: ${params.question}${optionsText}` }],
					details: { question: params.question, options: labels, answer: null, cancelled: true } satisfies AskUserDetails,
				};
			}

			if (multiSelect && labels.length > 0) {
				const instruction = allowFreeText
					? "Select one or more options by number, separated by commas. Or type a custom answer."
					: "Select one or more options by number, separated by commas.";
				const body = [
					prompt,
					"",
					instruction,
					"",
					...labels.map((label, index) => `${index + 1}. ${label}`),
				].join("\n");
				while (true) {
					const input = await ctx.ui.editor(body, params.default ?? "");
					if (input === undefined) {
						return {
							content: [{ type: "text", text: "User cancelled the question." }],
							details: { question: params.question, options: labels, answer: null, cancelled: true } satisfies AskUserDetails,
						};
					}
					const answer = parseMultiAnswer(input, labels);
					if (!allowFreeText && !Array.isArray(answer)) {
						ctx.ui.notify("Select options by number; free-text answers are disabled.", "error");
						continue;
					}
					const answerText = Array.isArray(answer) ? answer.join(", ") : answer;
					return {
						content: [{ type: "text", text: `User answered: ${answerText}` }],
						details: { question: params.question, options: labels, answer, cancelled: false, custom: !Array.isArray(answer) } satisfies AskUserDetails,
					};
				}
			}

			if (labels.length > 0) {
				const choices = allowFreeText ? [...labels, CUSTOM_OPTION] : labels;
				const selected = await ctx.ui.select(prompt, choices);
				if (selected === undefined) {
					return {
						content: [{ type: "text", text: "User cancelled the question." }],
						details: { question: params.question, options: labels, answer: null, cancelled: true } satisfies AskUserDetails,
					};
				}
				if (selected === CUSTOM_OPTION) {
					const input = await ctx.ui.editor(prompt, params.default ?? "");
					if (input === undefined) {
						return {
							content: [{ type: "text", text: "User cancelled the question." }],
							details: { question: params.question, options: labels, answer: null, cancelled: true } satisfies AskUserDetails,
						};
					}
					return {
						content: [{ type: "text", text: `User answered: ${input.trim()}` }],
						details: { question: params.question, options: labels, answer: input.trim(), cancelled: false, custom: true } satisfies AskUserDetails,
					};
				}
				return {
					content: [{ type: "text", text: `User selected: ${selected}` }],
					details: { question: params.question, options: labels, answer: selected, cancelled: false, custom: false } satisfies AskUserDetails,
				};
			}

			const input = await ctx.ui.editor(prompt, params.default ?? "");
			if (input === undefined) {
				return {
					content: [{ type: "text", text: "User cancelled the question." }],
					details: { question: params.question, options: [], answer: null, cancelled: true } satisfies AskUserDetails,
				};
			}
			return {
				content: [{ type: "text", text: `User answered: ${input.trim()}` }],
				details: { question: params.question, options: [], answer: input.trim(), cancelled: false, custom: true } satisfies AskUserDetails,
			};
		},
	});
}
