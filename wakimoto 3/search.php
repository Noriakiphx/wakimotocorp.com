<?php
/**
 * 検索結果テンプレート
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

get_header();
?>

<main id="primary" class="site-main">

	<header class="page-hero">
		<div class="page-hero__bg" aria-hidden="true"><span class="hero__grid"></span></div>
		<div class="container">
			<?php wakimoto_eyebrow( '—', 'SEARCH' ); ?>
			<h1 class="page-hero__title">
				<?php
				/* translators: %s: 検索キーワード */
				printf( esc_html__( '「%s」の検索結果', 'wakimoto' ), '<span>' . get_search_query() . '</span>' ); // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
				?>
			</h1>
		</div>
	</header>

	<div class="container content-area">
		<div class="content-main">
			<?php if ( have_posts() ) : ?>
				<div class="post-list">
					<?php
					while ( have_posts() ) :
						the_post();
						get_template_part( 'template-parts/content', 'search' );
					endwhile;
					?>
				</div>

				<?php
				the_posts_pagination(
					array(
						'mid_size'  => 1,
						'prev_text' => __( '前へ', 'wakimoto' ),
						'next_text' => __( '次へ', 'wakimoto' ),
					)
				);
				?>
			<?php else : ?>
				<?php get_template_part( 'template-parts/content', 'none' ); ?>
			<?php endif; ?>
		</div>

		<?php get_sidebar(); ?>
	</div>

</main>

<?php
get_footer();
