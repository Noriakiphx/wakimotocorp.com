<?php
/**
 * 404（ページが見つからない）テンプレート
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

get_header();
?>

<main id="primary" class="site-main error-404-main">

	<section class="error-404">
		<div class="error-404__bg" aria-hidden="true">
			<span class="hero__glow"></span>
			<?php wakimoto_array_motif(); ?>
		</div>
		<div class="container error-404__inner">
			<span class="error-404__code">404</span>
			<h1 class="error-404__title"><?php esc_html_e( 'ページが見つかりませんでした', 'wakimoto' ); ?></h1>
			<p class="error-404__text"><?php esc_html_e( 'お探しのページは移動または削除された可能性があります。以下から目的のページをお探しください。', 'wakimoto' ); ?></p>

			<div class="error-404__search">
				<?php get_search_form(); ?>
			</div>

			<a class="btn btn--accent" href="<?php echo esc_url( home_url( '/' ) ); ?>"><?php esc_html_e( 'トップへ戻る', 'wakimoto' ); ?></a>
		</div>
	</section>

</main>

<?php
get_footer();
