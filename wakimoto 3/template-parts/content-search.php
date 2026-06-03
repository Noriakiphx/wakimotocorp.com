<?php
/**
 * テンプレートパーツ：検索結果アイテム
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}
?>
<article id="post-<?php the_ID(); ?>" <?php post_class( 'search-result reveal' ); ?> data-reveal>
	<?php the_title( sprintf( '<h2 class="search-result__title"><a href="%s" rel="bookmark">', esc_url( get_permalink() ) ), '</a></h2>' ); ?>

	<?php if ( 'post' === get_post_type() ) : ?>
		<?php wakimoto_entry_meta(); ?>
	<?php endif; ?>

	<div class="search-result__summary">
		<?php the_excerpt(); ?>
	</div>
</article>
