import { LoginDialogComponent, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

type PatchableLoginDialog = {
	showAuth(url: string, instructions?: string): void;
	contentContainer: {
		children?: Array<{
			paddingX?: number;
			invalidate?: () => void;
		}>;
	};
	tui: {
		requestRender(): void;
	};
	__toolnixLoginUrlPaddingPatched?: boolean;
	__toolnixOriginalShowAuth?: (url: string, instructions?: string) => void;
};

export default function loginUrlPaddingExtension(_pi: ExtensionAPI): void {
	const prototype = LoginDialogComponent.prototype as unknown as PatchableLoginDialog;

	if (prototype.__toolnixLoginUrlPaddingPatched) {
		return;
	}

	const originalShowAuth = prototype.showAuth;

	prototype.showAuth = function showAuthWithZeroUrlPadding(this: PatchableLoginDialog, url: string, instructions?: string): void {
		originalShowAuth.call(this, url, instructions);

		// Upstream currently renders showAuth as: Spacer, URL Text, click-hint Text, ...
		// The URL Text's left padding breaks terminal URL detection/copy when it wraps.
		const urlText = this.contentContainer.children?.[1];
		if (urlText && typeof urlText.paddingX === "number") {
			urlText.paddingX = 0;
			urlText.invalidate?.();
			this.tui.requestRender();
		}
	};

	prototype.__toolnixOriginalShowAuth = originalShowAuth;
	prototype.__toolnixLoginUrlPaddingPatched = true;
}
