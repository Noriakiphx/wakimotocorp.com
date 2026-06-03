/**
 * Wakimoto Shokai — SoundAssist
 * フロントエンドの基本的なインタラクション
 */
(function () {
	'use strict';

	document.addEventListener('DOMContentLoaded', function () {

		/* ---------- モバイルナビの開閉 ---------- */
		var toggle = document.querySelector('[data-menu-toggle]');
		var nav = document.getElementById('site-navigation');

		if (toggle && nav) {
			toggle.addEventListener('click', function () {
				var isOpen = nav.classList.toggle('is-open');
				toggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
				document.body.style.overflow = isOpen ? 'hidden' : '';
			});

			// メニュー内リンクをタップしたら閉じる
			nav.addEventListener('click', function (e) {
				var link = e.target.closest('a');
				if (link && nav.classList.contains('is-open')) {
					nav.classList.remove('is-open');
					toggle.setAttribute('aria-expanded', 'false');
					document.body.style.overflow = '';
				}
			});

			// Esc キーで閉じる
			document.addEventListener('keydown', function (e) {
				if (e.key === 'Escape' && nav.classList.contains('is-open')) {
					nav.classList.remove('is-open');
					toggle.setAttribute('aria-expanded', 'false');
					document.body.style.overflow = '';
					toggle.focus();
				}
			});
		}

		/* ---------- ヘッダーのスクロール状態 ---------- */
		var header = document.querySelector('[data-header]');
		if (header) {
			var onScroll = function () {
				if (window.scrollY > 12) {
					header.classList.add('is-scrolled');
				} else {
					header.classList.remove('is-scrolled');
				}
			};
			onScroll();
			window.addEventListener('scroll', onScroll, { passive: true });
		}

		/* ---------- スクロールリビール ---------- */
		var revealItems = document.querySelectorAll('[data-reveal]');
		var prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

		if (revealItems.length) {
			if (prefersReduced || !('IntersectionObserver' in window)) {
				revealItems.forEach(function (el) { el.classList.add('is-visible'); });
			} else {
				var observer = new IntersectionObserver(function (entries, obs) {
					entries.forEach(function (entry) {
						if (entry.isIntersecting) {
							entry.target.classList.add('is-visible');
							obs.unobserve(entry.target);
						}
					});
				}, { threshold: 0.12, rootMargin: '0px 0px -8% 0px' });

				revealItems.forEach(function (el) { observer.observe(el); });
			}
		}

		/* ---------- ページ上部へ（スムーズスクロール） ---------- */
		var toTop = document.querySelector('[data-to-top]');
		if (toTop) {
			toTop.addEventListener('click', function (e) {
				e.preventDefault();
				window.scrollTo({
					top: 0,
					behavior: prefersReduced ? 'auto' : 'smooth'
				});
			});
		}
	});
})();
