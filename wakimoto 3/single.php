<?php
/**
 * 投稿（single）用テンプレート
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
				<?php wakimoto_entry_meta(); ?>
				<h1 class="page-hero__title"><?php the_title(); ?></h1>
			</div>
		</header>

		<div class="container content-area">
			<div class="content-main">
				<article id="post-<?php the_ID(); ?>" <?php post_class( 'single-article' ); ?>>
					<?php wakimoto_post_thumbnail( 'wakimoto-wide' ); ?>

					<div class="entry-content prose">
						<?php
						the_content(
							sprintf(
								wp_kses(
									/* translators: %s: 投稿タイトル */
									__( '続きを読む<span class="screen-reader-text"> 「%s」</span>', 'wakimoto' ),
									array( 'span' => array( 'class' => array() ) )
								),
								wp_kses_post( get_the_title() )
							)
						);

						wp_link_pages(
							array(
								'before' => '<div class="page-links">' . esc_html__( 'ページ:', 'wakimoto' ),
								'after'  => '</div>',
							)
						);
						?>
					</div>

					<footer class="entry-footer">
						<?php wakimoto_entry_footer(); ?>
					</footer>
				</article>

				<nav class="post-nav" aria-label="<?php esc_attr_e( '投稿ナビゲーション', 'wakimoto' ); ?>">
					<div class="post-nav__prev"><?php previous_post_link( '%link', '← %title' ); ?></div>
					<div class="post-nav__next"><?php next_post_link( '%link', '%title →' ); ?></div>
				</nav>

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
