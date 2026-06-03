<?php
/**
 * サイトヘッダー
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}
?>
<!doctype html>
<html <?php language_attributes(); ?>>
<head>
	<meta charset="<?php bloginfo( 'charset' ); ?>">
	<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
	<link rel="profile" href="https://gmpg.org/xfn/11">
	<?php wp_head(); ?>
</head>

<body <?php body_class(); ?>>
<?php wp_body_open(); ?>
<div id="page" class="site">
	<a class="skip-link screen-reader-text" href="#primary"><?php esc_html_e( 'コンテンツへスキップ', 'wakimoto' ); ?></a>

	<header id="masthead" class="site-header" data-header>
		<div class="site-header__inner container">

			<div class="site-branding">
				<?php
				if ( has_custom_logo() ) {
					the_custom_logo();
				} else {
					if ( is_front_page() && is_home() ) {
						?>
						<h1 class="site-title"><a href="<?php echo esc_url( home_url( '/' ) ); ?>" rel="home"><?php bloginfo( 'name' ); ?></a></h1>
						<?php
					} else {
						?>
						<p class="site-title"><a href="<?php echo esc_url( home_url( '/' ) ); ?>" rel="home"><?php bloginfo( 'name' ); ?></a></p>
						<?php
					}
					$wakimoto_description = get_bloginfo( 'description', 'display' );
					if ( $wakimoto_description ) {
						?>
						<p class="site-description"><?php echo esc_html( $wakimoto_description ); ?></p>
						<?php
					}
				}
				?>
			</div><!-- .site-branding -->

			<nav id="site-navigation" class="main-navigation" aria-label="<?php esc_attr_e( 'グローバルナビ', 'wakimoto' ); ?>">
				<?php
				if ( has_nav_menu( 'primary' ) ) {
					wp_nav_menu(
						array(
							'theme_location' => 'primary',
							'menu_id'        => 'primary-menu',
							'menu_class'     => 'primary-menu',
							'container'      => false,
							'depth'          => 2,
						)
					);
				} else {
					?>
					<ul class="primary-menu">
						<?php
						wp_list_pages(
							array(
								'title_li' => '',
								'depth'    => 1,
							)
						);
						?>
					</ul>
					<?php
				}
				?>
			</nav><!-- #site-navigation -->

			<div class="site-header__actions">
				<?php
				$wakimoto_phone = wakimoto_get_mod( 'wakimoto_header_phone' );
				if ( $wakimoto_phone ) {
					$wakimoto_tel = preg_replace( '/[^0-9+]/', '', $wakimoto_phone );
					?>
					<a class="header-phone" href="tel:<?php echo esc_attr( $wakimoto_tel ); ?>">
						<span class="header-phone__label"><?php esc_html_e( 'TEL', 'wakimoto' ); ?></span>
						<span class="header-phone__num"><?php echo esc_html( $wakimoto_phone ); ?></span>
					</a>
					<?php
				}
				$wakimoto_cta_label = wakimoto_get_mod( 'wakimoto_header_cta_label' );
				$wakimoto_cta_url   = wakimoto_get_mod( 'wakimoto_header_cta_url' );
				if ( $wakimoto_cta_label && $wakimoto_cta_url ) {
					?>
					<a class="btn btn--accent btn--sm header-cta" href="<?php echo esc_url( $wakimoto_cta_url ); ?>"><?php echo esc_html( $wakimoto_cta_label ); ?></a>
					<?php
				}
				?>
				<button class="menu-toggle" aria-controls="site-navigation" aria-expanded="false" data-menu-toggle>
					<span class="menu-toggle__bars" aria-hidden="true"><span></span><span></span><span></span></span>
					<span class="screen-reader-text"><?php esc_html_e( 'メニューを開閉', 'wakimoto' ); ?></span>
				</button>
			</div><!-- .site-header__actions -->

		</div><!-- .site-header__inner -->
	</header><!-- #masthead -->

	<div id="content" class="site-content">
