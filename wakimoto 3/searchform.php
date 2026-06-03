<?php
/**
 * 検索フォーム
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$wakimoto_sf_id = 'search-field-' . wp_unique_id();
?>
<form role="search" method="get" class="search-form" action="<?php echo esc_url( home_url( '/' ) ); ?>">
	<label for="<?php echo esc_attr( $wakimoto_sf_id ); ?>" class="screen-reader-text"><?php esc_html_e( '検索:', 'wakimoto' ); ?></label>
	<div class="search-form__inner">
		<input type="search" id="<?php echo esc_attr( $wakimoto_sf_id ); ?>" class="search-field" placeholder="<?php esc_attr_e( 'キーワードを入力', 'wakimoto' ); ?>" value="<?php echo get_search_query(); ?>" name="s" />
		<button type="submit" class="search-submit">
			<svg viewBox="0 0 24 24" width="18" height="18" fill="none" aria-hidden="true"><circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="2"/><path d="m21 21-4.3-4.3" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
			<span class="screen-reader-text"><?php esc_html_e( '検索', 'wakimoto' ); ?></span>
		</button>
	</div>
</form>
