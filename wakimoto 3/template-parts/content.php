<?php
/**
 * テンプレートパーツ：投稿カード（一覧用）
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}
?>
<article id="post-<?php the_ID(); ?>" <?php post_class( 'post-card reveal' ); ?> data-reveal>
	<?php if ( has_post_thumbnail() ) : ?>
		<div class="post-card__media">
			<?php wakimoto_post_thumbnail( 'wakimoto-card' ); ?>
		</div>
	<?php endif; ?>

	<div class="post-card__body">
		<?php wakimoto_entry_meta(); ?>

		<?php
		the_title(
			sprintf( '<h2 class="post-card__title"><a href="%s" rel="bookmark">', esc_url( get_permalink() ) ),
			'</a></h2>'
		);
		?>

		<?php if ( ! is_singular() ) : ?>
			<div class="post-card__excerpt">
				<?php the_excerpt(); ?>
			</div>
		<?php endif; ?>

		<a class="post-card__more" href="<?php the_permalink(); ?>">
			<span><?php esc_html_e( '記事を読む', 'wakimoto' ); ?></span>
			<svg viewBox="0 0 24 24" width="16" height="16" fill="none" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
		</a>
	</div>
</article>
