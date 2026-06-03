<?php
/**
 * テンプレート用ヘルパー関数
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

if ( ! function_exists( 'wakimoto_get_mod' ) ) :
	/**
	 * theme_mod を取得（デフォルト付き）するショートカット
	 *
	 * @param string $key     設定キー。
	 * @param mixed  $default 既定値。
	 * @return mixed
	 */
	function wakimoto_get_mod( $key, $default = '' ) {
		return get_theme_mod( $key, $default );
	}
endif;

if ( ! function_exists( 'wakimoto_posted_on' ) ) :
	/**
	 * 投稿日を表示
	 */
	function wakimoto_posted_on() {
		$time_string = '<time class="entry-date published updated" datetime="%1$s">%2$s</time>';
		if ( get_the_time( 'U' ) !== get_the_modified_time( 'U' ) ) {
			$time_string = '<time class="entry-date published" datetime="%1$s">%2$s</time><time class="updated" datetime="%3$s">%4$s</time>';
		}

		$time_string = sprintf(
			$time_string,
			esc_attr( get_the_date( DATE_W3C ) ),
			esc_html( get_the_date() ),
			esc_attr( get_the_modified_date( DATE_W3C ) ),
			esc_html( get_the_modified_date() )
		);

		printf(
			'<span class="posted-on"><span class="screen-reader-text">%1$s</span>%2$s</span>',
			esc_html__( '投稿日', 'wakimoto' ),
			$time_string // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
		);
	}
endif;

if ( ! function_exists( 'wakimoto_posted_by' ) ) :
	/**
	 * 投稿者を表示
	 */
	function wakimoto_posted_by() {
		printf(
			'<span class="byline"><span class="screen-reader-text">%1$s</span><a class="url fn n" href="%2$s">%3$s</a></span>',
			esc_html__( '投稿者', 'wakimoto' ),
			esc_url( get_author_posts_url( get_the_author_meta( 'ID' ) ) ),
			esc_html( get_the_author() )
		);
	}
endif;

if ( ! function_exists( 'wakimoto_entry_meta' ) ) :
	/**
	 * 投稿メタ（日付・カテゴリー）をまとめて表示
	 */
	function wakimoto_entry_meta() {
		if ( 'post' !== get_post_type() ) {
			return;
		}
		echo '<div class="entry-meta">';
		wakimoto_posted_on();
		$categories = get_the_category_list( '、' );
		if ( $categories ) {
			echo '<span class="cat-links">' . $categories . '</span>'; // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
		}
		echo '</div>';
	}
endif;

if ( ! function_exists( 'wakimoto_entry_footer' ) ) :
	/**
	 * 投稿フッター（タグ・コメント）
	 */
	function wakimoto_entry_footer() {
		if ( 'post' === get_post_type() ) {
			$tags_list = get_the_tag_list( '', ' ' );
			if ( $tags_list ) {
				printf(
					'<div class="tags-links">%1$s %2$s</div>',
					esc_html__( 'タグ:', 'wakimoto' ),
					$tags_list // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
				);
			}
		}
	}
endif;

if ( ! function_exists( 'wakimoto_post_thumbnail' ) ) :
	/**
	 * アイキャッチ画像を表示（ある場合のみ）
	 *
	 * @param string $size 画像サイズ。
	 */
	function wakimoto_post_thumbnail( $size = 'wakimoto-card' ) {
		if ( post_password_required() || is_attachment() || ! has_post_thumbnail() ) {
			return;
		}

		if ( is_singular() ) {
			echo '<figure class="post-thumbnail">';
			the_post_thumbnail( $size );
			echo '</figure>';
		} else {
			?>
			<a class="post-thumbnail" href="<?php the_permalink(); ?>" aria-hidden="true" tabindex="-1">
				<?php the_post_thumbnail( $size, array( 'alt' => the_title_attribute( array( 'echo' => false ) ) ) ); ?>
			</a>
			<?php
		}
	}
endif;

if ( ! function_exists( 'wakimoto_eyebrow' ) ) :
	/**
	 * 各セクション見出しの上に表示する「アイブロウ」ラベル
	 *
	 * @param string $index ラベル番号（例: 01）。
	 * @param string $label ラベルテキスト。
	 */
	function wakimoto_eyebrow( $index, $label ) {
		printf(
			'<span class="eyebrow"><span class="eyebrow__index">%1$s</span><span class="eyebrow__label">%2$s</span></span>',
			esc_html( $index ),
			esc_html( $label )
		);
	}
endif;

if ( ! function_exists( 'wakimoto_array_motif' ) ) :
	/**
	 * ラインアレイ／波形をモチーフにした装飾 SVG
	 */
	function wakimoto_array_motif() {
		?>
		<svg class="array-motif" viewBox="0 0 240 320" fill="none" aria-hidden="true" focusable="false" xmlns="http://www.w3.org/2000/svg">
			<g class="array-motif__cabs">
				<?php
				// 上から下へ、ラインアレイのように少しずつ角度をつけて並べる
				$count = 9;
				$y     = 18;
				for ( $i = 0; $i < $count; $i++ ) {
					$tilt = $i * 1.4;
					$w    = 150 + $i * 6;
					$h    = 20;
					$x    = 120 - $w / 2;
					printf(
						'<rect x="%1$.1f" y="%2$.1f" width="%3$.1f" height="%4$d" rx="3" transform="rotate(%5$.2f 120 %6$.1f)" />',
						$x,
						$y,
						$w,
						$h,
						$tilt,
						$y + $h / 2
					);
					$y += $h + 9 + $i * 1.2;
				}
				?>
			</g>
		</svg>
		<?php
	}
endif;

if ( ! function_exists( 'wakimoto_social_links' ) ) :
	/**
	 * フッター用 SNS リンクを出力
	 */
	function wakimoto_social_links() {
		$socials = array(
			'x'         => array( 'label' => 'X', 'url' => wakimoto_get_mod( 'wakimoto_social_x' ) ),
			'facebook'  => array( 'label' => 'Facebook', 'url' => wakimoto_get_mod( 'wakimoto_social_facebook' ) ),
			'instagram' => array( 'label' => 'Instagram', 'url' => wakimoto_get_mod( 'wakimoto_social_instagram' ) ),
			'youtube'   => array( 'label' => 'YouTube', 'url' => wakimoto_get_mod( 'wakimoto_social_youtube' ) ),
			'line'      => array( 'label' => 'LINE', 'url' => wakimoto_get_mod( 'wakimoto_social_line' ) ),
		);

		$has_any = false;
		foreach ( $socials as $s ) {
			if ( ! empty( $s['url'] ) ) {
				$has_any = true;
				break;
			}
		}
		if ( ! $has_any ) {
			return;
		}

		echo '<ul class="social-links" aria-label="' . esc_attr__( 'SNS', 'wakimoto' ) . '">';
		foreach ( $socials as $key => $s ) {
			if ( empty( $s['url'] ) ) {
				continue;
			}
			printf(
				'<li><a href="%1$s" target="_blank" rel="noopener noreferrer"><span>%2$s</span></a></li>',
				esc_url( $s['url'] ),
				esc_html( $s['label'] )
			);
		}
		echo '</ul>';
	}
endif;
