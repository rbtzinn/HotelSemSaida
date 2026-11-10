(() => {
	"use strict";

	document.querySelectorAll(".compare").forEach((comparison) => {
		const input = comparison.querySelector('input[type="range"]');
		if (!input) return;
		const update = () => {
			const position = Math.min(100, Math.max(0, Number(input.value) || 0));
			comparison.style.setProperty("--pos", `${position}%`);
			input.setAttribute("aria-valuetext", `${position}% de 1923 e ${100 - position}% de hoje`);
		};
		input.addEventListener("input", update);
		input.disabled = false;
		comparison.classList.add("is-interactive");
		update();
	});
	document.querySelectorAll("[data-compare-instruction]").forEach((instruction) => {
		instruction.hidden = false;
	});

	const menu = document.querySelector("details#mobile-menu");
	if (menu) {
		menu.addEventListener("click", (event) => {
			if (event.target.closest("a[href]")) menu.open = false;
		});
		document.addEventListener("keydown", (event) => {
			if (event.key !== "Escape" || !menu.open) return;
			event.preventDefault();
			menu.open = false;
			menu.querySelector("summary")?.focus();
		});
	}

	function downloadURL(asset) {
		if (!asset || typeof asset.name !== "string" || !/\.zip$/i.test(asset.name)
			|| typeof asset.browser_download_url !== "string") return null;
		try {
			const url = new URL(asset.browser_download_url);
			const prefix = "/rbtzinn/HotelSemSaida/releases/download/";
			return url.protocol === "https:" && url.hostname === "github.com"
				&& !url.username && !url.password && !url.port
				&& url.pathname.startsWith(prefix) && url.pathname.length > prefix.length
				? url.href : null;
		} catch {
			return null;
		}
	}

	async function resolveDownload() {
		const controller = new AbortController();
		const timeout = setTimeout(() => controller.abort(), 8000);
		try {
			const response = await fetch("https://api.github.com/repos/rbtzinn/HotelSemSaida/releases?per_page=30", {
				signal: controller.signal,
				headers: { Accept: "application/vnd.github+json" },
			});
			if (!response.ok) return;
			const data = await response.json();
			if (!Array.isArray(data)) return;
			const releases = data.filter((release) => release && release.draft === false
				&& release.prerelease === false && typeof release.tag_name === "string"
				&& release.tag_name.trim() && Array.isArray(release.assets));
			if (!releases.length) return;
			const full = releases.find((release) => release.assets.some((asset) => downloadURL(asset)));
			if (!full) return;
			const zip = full.assets.find((asset) => downloadURL(asset));
			const url = downloadURL(zip);
			const version = full.tag_name.replace(/^v/, "");
			const latest = releases[0].tag_name.replace(/^v/, "");
			const size = Number.isFinite(zip.size) && zip.size > 0
				? ` · ${Math.max(1, Math.round(zip.size / 1048576))} MB` : "";
			const description = version === latest
				? `Versão ${version}${size} · Windows 64 bits · grátis`
				: `Versão ${version}${size} · atualização ${latest} disponível no jogo`;
			document.querySelectorAll("[data-download]").forEach((link) => { link.href = url; });
			document.querySelectorAll("[data-release]").forEach((label) => { label.textContent = description; });
		} catch {
			// Sem rede, o link para o Release e a descrição do HTML continuam disponíveis.
		} finally {
			clearTimeout(timeout);
		}
	}

	resolveDownload();
})();
