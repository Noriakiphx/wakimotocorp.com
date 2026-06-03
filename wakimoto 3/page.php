<?php
/**
 * 固定ページ用テンプレート
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

get_header();
?>

<main id="primary" class="site-main">

	<?php
	while ( have_posts() ) :
		the_post();
		?>
		<header class="page-hero">
			<div class="page-hero__bg" aria-hidden="true"><span class="hero__grid"></span></div>
			<div class="container">
				<?php wakimoto_eyebrow( '—', 'PAGE' ); ?>
				<h1 class="page-hero__title"><?php the_title(); ?></h1>
			</div>
		</header>

		<div class="container content-area">
			<div class="content-main">
				<article id="post-<?php the_ID(); ?>" <?php post_class( 'page-article' ); ?>>
					<?php wakimoto_post_thumbnail( 'wakimoto-wide' ); ?>

					<div class="entry-content prose">
						<?php
						the_content();

						wp_link_pages(
							array(
								'before' => '<div class="page-links">' . esc_html__( 'ページ:', 'wakimoto' ),
								'after'  => '</div>',
							)
						);
						?>
					</div>

					<?php if ( get_edit_post_link() ) : ?>
						<footer class="entry-footer">
							<?php
							edit_post_link(
								sprintf(
									/* translators: %s: ページタイトル */
									__( '%s を編集', 'wakimoto' ),
									the_title( '<span class="screen-reader-text">「', '」</span>', false )
								),
								'<span class="edit-link">',
								'</span>'
							);
							?>
						</footer>
					<?php endif; ?>
				</article>

				<?php
				if ( comments_open() || get_comments_number() ) {
					comments_template();
				}
				?>
			</div>

			<?php get_sidebar(); ?>
		</div>
		<?php
	endwhile;
	?>

</main>

<?php
get_footer();
