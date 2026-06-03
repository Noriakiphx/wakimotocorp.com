<?php
/**
 * Template Name: 全幅（サイドバーなし）
 *
 * サイドバーを表示しない、横幅いっぱいの固定ページテンプレートです。
 * 固定ページ編集画面の「ページ属性 > テンプレート」から選択できます。
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

get_header();
?>

<main id="primary" class="site-main is-full-width">

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

		<div class="container">
			<article id="post-<?php the_ID(); ?>" <?php post_class( 'page-article page-article--wide' ); ?>>
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
			</article>

			<?php
			if ( comments_open() || get_comments_number() ) {
				comments_template();
			}
			?>
		</div>
		<?php
	endwhile;
	?>

</main>

<?php
get_footer();
