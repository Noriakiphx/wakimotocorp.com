<?php
/**
 * アーカイブ（カテゴリー・タグ・日付・著者）用テンプレート
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
			<?php wakimoto_eyebrow( '—', 'ARCHIVE' ); ?>
			<?php
			the_archive_title( '<h1 class="page-hero__title">', '</h1>' );
			the_archive_description( '<div class="page-hero__desc">', '</div>' );
			?>
		</div>
	</header>

	<div class="container content-area">
		<div class="content-main">
			<?php if ( have_posts() ) : ?>
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
