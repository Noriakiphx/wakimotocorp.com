<?php
/**
 * テンプレートパーツ：投稿が見つからない場合
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}
?>
<section class="no-results not-found">
	<header class="no-results__head">
		<h2><?php esc_html_e( '見つかりませんでした', 'wakimoto' ); ?></h2>
	</header>

	<div class="no-results__body prose">
		<?php if ( is_home() && current_user_can( 'publish_posts' ) ) : ?>
			<p>
				<?php
				printf(
					wp_kses(
						/* translators: %s: 新規投稿リンク */
						__( '最初の記事を <a href="%s">投稿してみましょう</a>。', 'wakimoto' ),
						array( 'a' => array( 'href' => array() ) )
					),
					esc_url( admin_url( 'post-new.php' ) )
				);
				?>
			</p>
		<?php elseif ( is_search() ) : ?>
			<p><?php esc_html_e( 'お探しのキーワードに一致する内容は見つかりませんでした。別のキーワードでお試しください。', 'wakimoto' ); ?></p>
			<?php get_search_form(); ?>
		<?php else : ?>
			<p><?php esc_html_e( 'お探しの内容は見つかりませんでした。検索をお試しください。', 'wakimoto' ); ?></p>
			<?php get_search_form(); ?>
		<?php endif; ?>
	</div>
</section>
