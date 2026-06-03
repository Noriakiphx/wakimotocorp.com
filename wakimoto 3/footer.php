<?php
/**
 * サイトフッター
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$wakimoto_company   = wakimoto_get_mod( 'wakimoto_company_name', '脇本商会 / SoundAssist' );
$wakimoto_tagline   = wakimoto_get_mod( 'wakimoto_company_tagline' );
$wakimoto_address   = wakimoto_get_mod( 'wakimoto_company_address' );
$wakimoto_phone     = wakimoto_get_mod( 'wakimoto_company_phone' );
$wakimoto_email     = wakimoto_get_mod( 'wakimoto_company_email' );
$wakimoto_copyright = wakimoto_get_mod( 'wakimoto_copyright', '脇本商会' );
$wakimoto_has_wid   = ( is_active_sidebar( 'footer-1' ) || is_active_sidebar( 'footer-2' ) || is_active_sidebar( 'footer-3' ) );
?>
	</div><!-- #content -->

	<footer id="colophon" class="site-footer">
		<?php wakimoto_array_motif(); ?>
		<div class="container">

			<div class="site-footer__top">
				<div class="site-footer__brand">
					<p class="site-footer__name"><?php echo esc_html( $wakimoto_company ); ?></p>
					<?php if ( $wakimoto_tagline ) : ?>
						<p class="site-footer__tagline"><?php echo esc_html( $wakimoto_tagline ); ?></p>
					<?php endif; ?>

					<address class="site-footer__address">
						<?php if ( $wakimoto_address ) : ?>
							<span class="site-footer__line"><?php echo nl2br( esc_html( $wakimoto_address ) ); ?></span>
						<?php endif; ?>
						<?php if ( $wakimoto_phone ) : ?>
							<span class="site-footer__line">
								<span class="label">TEL</span>
								<a href="tel:<?php echo esc_attr( preg_replace( '/[^0-9+]/', '', $wakimoto_phone ) ); ?>"><?php echo esc_html( $wakimoto_phone ); ?></a>
							</span>
						<?php endif; ?>
						<?php if ( $wakimoto_email ) : ?>
							<span class="site-footer__line">
								<span class="label">MAIL</span>
								<a href="mailto:<?php echo esc_attr( $wakimoto_email ); ?>"><?php echo esc_html( $wakimoto_email ); ?></a>
							</span>
						<?php endif; ?>
					</address>

					<?php wakimoto_social_links(); ?>
				</div>

				<div class="site-footer__nav">
					<?php
					if ( has_nav_menu( 'footer' ) ) {
						wp_nav_menu(
							array(
								'theme_location' => 'footer',
								'menu_class'     => 'footer-menu',
								'container'      => 'nav',
								'container_class' => 'footer-menu-wrap',
								'container_aria_label' => __( 'フッターナビ', 'wakimoto' ),
								'depth'          => 1,
							)
						);
					}
					?>
				</div>

				<?php if ( $wakimoto_has_wid ) : ?>
					<div class="site-footer__widgets">
						<?php for ( $i = 1; $i <= 3; $i++ ) : ?>
							<?php if ( is_active_sidebar( 'footer-' . $i ) ) : ?>
								<div class="footer-widget-area">
									<?php dynamic_sidebar( 'footer-' . $i ); ?>
								</div>
							<?php endif; ?>
						<?php endfor; ?>
					</div>
				<?php endif; ?>
			</div>

			<div class="site-footer__bottom">
				<p class="site-footer__copy">
					&copy; <?php echo esc_html( gmdate( 'Y' ) ); ?> <?php echo esc_html( $wakimoto_copyright ); ?>. All rights reserved.
				</p>
				<a href="#page" class="to-top" data-to-top>
					<span><?php esc_html_e( 'ページ上部へ', 'wakimoto' ); ?></span>
					<svg viewBox="0 0 24 24" width="16" height="16" fill="none" aria-hidden="true"><path d="M12 19V5M5 12l7-7 7 7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
				</a>
			</div>

		</div><!-- .container -->
	</footer><!-- #colophon -->
</div><!-- #page -->

<?php wp_footer(); ?>
</body>
</html>
