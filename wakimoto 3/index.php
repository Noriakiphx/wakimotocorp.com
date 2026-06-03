<?php
/**
 * メインテンプレート（投稿一覧・フォールバック）
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

get_header();
?>

<main id="primary" class="site-main">
	<div class="container content-area">

		<div class="content-main">
			<?php if ( have_posts() ) : ?>

				<header class="archive-header">
					<?php wakimoto_eyebrow( '—', 'NEWS & TOPICS' ); ?>
					<h1 class="archive-title">
						<?php
						if ( is_home() && ! is_front_page() ) {
							single_post_title();
						} else {
							esc_html_e( 'お知らせ', 'wakimoto' );
						}
						?>
					</h1>
				</header>

				<div class="post-list">
					<?php
					while ( have_posts() ) :
						the_post();
						get_template_part( 'template-parts/content', get_post_type() );
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
