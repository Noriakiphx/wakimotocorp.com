<?php
/**
 * コメントテンプレート
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

if ( post_password_required() ) {
	return;
}
?>
<div id="comments" class="comments-area">

	<?php if ( have_comments() ) : ?>
		<h2 class="comments-title">
			<?php
			$wakimoto_comment_count = get_comments_number();
			if ( '1' === $wakimoto_comment_count ) {
				esc_html_e( '1件のコメント', 'wakimoto' );
			} else {
				/* translators: %s: コメント数 */
				printf( esc_html__( '%s件のコメント', 'wakimoto' ), esc_html( number_format_i18n( $wakimoto_comment_count ) ) );
			}
			?>
		</h2>

		<ol class="comment-list">
			<?php
			wp_list_comments(
				array(
					'style'      => 'ol',
					'short_ping' => true,
					'avatar_size' => 48,
				)
			);
			?>
		</ol>

		<?php
		the_comments_pagination(
			array(
				'prev_text' => __( '前のコメント', 'wakimoto' ),
				'next_text' => __( '次のコメント', 'wakimoto' ),
			)
		);
		?>

		<?php if ( ! comments_open() ) : ?>
			<p class="no-comments"><?php esc_html_e( 'コメントは受け付けていません。', 'wakimoto' ); ?></p>
		<?php endif; ?>

	<?php endif; ?>

	<?php
	comment_form(
		array(
			'title_reply'        => __( 'コメントを残す', 'wakimoto' ),
			'class_submit'       => 'btn btn--accent',
			'label_submit'       => __( '送信する', 'wakimoto' ),
		)
	);
	?>

</div>
