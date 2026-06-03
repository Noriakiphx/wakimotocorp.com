<?php
/**
 * Wakimoto Shokai — SoundAssist functions and definitions
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit; // 直接アクセスを禁止
}

if ( ! defined( 'WAKIMOTO_VERSION' ) ) {
	define( 'WAKIMOTO_VERSION', '1.0.0' );
}

/**
 * テーマの基本セットアップ
 */
function wakimoto_setup() {
	// 翻訳ファイルの読み込み（/languages/ に .mo を置けば多言語化可能）
	load_theme_textdomain( 'wakimoto', get_template_directory() . '/languages' );

	// <title> タグを WordPress に任せる
	add_theme_support( 'title-tag' );

	// アイキャッチ画像を有効化
	add_theme_support( 'post-thumbnails' );

	// HTML5 マークアップ
	add_theme_support(
		'html5',
		array(
			'search-form',
			'comment-form',
			'comment-list',
			'gallery',
			'caption',
			'style',
			'script',
			'navigation-widgets',
		)
	);

	// カスタムロゴ
	add_theme_support(
		'custom-logo',
		array(
			'height'      => 96,
			'width'       => 320,
			'flex-width'  => true,
			'flex-height' => true,
		)
	);

	// 自動 RSS フィードリンク
	add_theme_support( 'automatic-feed-links' );

	// ブロックエディタのスタイル対応
	add_theme_support( 'editor-styles' );
	add_theme_support( 'responsive-embeds' );
	add_theme_support( 'wp-block-styles' );
	add_theme_support( 'align-wide' );
	add_editor_style( 'assets/css/editor-style.css' );

	// WooCommerce（rental.wakimotocorp.com 等で使う場合に備えて宣言）
	add_theme_support( 'woocommerce' );

	// メニューの登録
	register_nav_menus(
		array(
			'primary' => __( 'グローバルナビ（ヘッダー）', 'wakimoto' ),
			'footer'  => __( 'フッターナビ', 'wakimoto' ),
		)
	);

	// 追加の画像サイズ（事業カード／ニュースサムネイル）
	add_image_size( 'wakimoto-card', 800, 600, true );
	add_image_size( 'wakimoto-wide', 1600, 900, true );
}
add_action( 'after_setup_theme', 'wakimoto_setup' );

/**
 * コンテンツ幅
 */
function wakimoto_content_width() {
	$GLOBALS['content_width'] = apply_filters( 'wakimoto_content_width', 1100 );
}
add_action( 'after_setup_theme', 'wakimoto_content_width', 0 );

/**
 * スタイル・スクリプトの読み込み
 */
function wakimoto_scripts() {
	// Google Fonts（Archivo / Zen Kaku Gothic New / IBM Plex Mono）
	wp_enqueue_style(
		'wakimoto-fonts',
		'https://fonts.googleapis.com/css2?family=Archivo:wght@400;500;600;700;800;900&family=Zen+Kaku+Gothic+New:wght@400;500;700;900&family=IBM+Plex+Mono:wght@400;500;600&display=swap',
		array(),
		null
	);

	// テーマ本体のスタイル
	wp_enqueue_style(
		'wakimoto-main',
		get_template_directory_uri() . '/assets/css/main.css',
		array( 'wakimoto-fonts' ),
		WAKIMOTO_VERSION
	);

	// テーマヘッダー情報用（style.css 自体も読み込んでおく）
	wp_enqueue_style(
		'wakimoto-style',
		get_stylesheet_uri(),
		array( 'wakimoto-main' ),
		WAKIMOTO_VERSION
	);

	// メインスクリプト
	wp_enqueue_script(
		'wakimoto-main',
		get_template_directory_uri() . '/assets/js/main.js',
		array(),
		WAKIMOTO_VERSION,
		true
	);

	// コメント返信スクリプト
	if ( is_singular() && comments_open() && get_option( 'thread_comments' ) ) {
		wp_enqueue_script( 'comment-reply' );
	}
}
add_action( 'wp_enqueue_scripts', 'wakimoto_scripts' );

/**
 * ウィジェットエリア（フッター3カラム＋サイドバー）
 */
function wakimoto_widgets_init() {
	$footer_args = array(
		'before_widget' => '<section id="%1$s" class="widget %2$s">',
		'after_widget'  => '</section>',
		'before_title'  => '<h2 class="widget-title">',
		'after_title'   => '</h2>',
	);

	for ( $i = 1; $i <= 3; $i++ ) {
		register_sidebar(
			array_merge(
				$footer_args,
				array(
					/* translators: %d: フッターウィジェットの番号 */
					'name'        => sprintf( __( 'フッター %d', 'wakimoto' ), $i ),
					'id'          => 'footer-' . $i,
					'description' => __( 'フッターに表示されるウィジェットエリアです。', 'wakimoto' ),
				)
			)
		);
	}

	register_sidebar(
		array(
			'name'          => __( 'サイドバー', 'wakimoto' ),
			'id'            => 'sidebar-1',
			'description'   => __( '投稿・固定ページの右側に表示されるウィジェットエリアです。', 'wakimoto' ),
			'before_widget' => '<section id="%1$s" class="widget %2$s">',
			'after_widget'  => '</section>',
			'before_title'  => '<h2 class="widget-title">',
			'after_title'   => '</h2>',
		)
	);
}
add_action( 'widgets_init', 'wakimoto_widgets_init' );

/**
 * body_class にユーティリティクラスを追加
 */
function wakimoto_body_classes( $classes ) {
	if ( ! is_singular() ) {
		$classes[] = 'hfeed';
	}
	if ( ! is_active_sidebar( 'sidebar-1' ) ) {
		$classes[] = 'no-sidebar';
	}
	if ( is_front_page() ) {
		$classes[] = 'is-front';
	}
	return $classes;
}
add_filter( 'body_class', 'wakimoto_body_classes' );

/**
 * 抜粋の文字数・省略記号（日本語向けに調整）
 */
function wakimoto_excerpt_length( $length ) {
	return 80;
}
add_filter( 'excerpt_length', 'wakimoto_excerpt_length' );

function wakimoto_excerpt_more( $more ) {
	return '…';
}
add_filter( 'excerpt_more', 'wakimoto_excerpt_more' );

/**
 * 必要ファイルの読み込み
 */
require get_template_directory() . '/inc/template-tags.php';
require get_template_directory() . '/inc/customizer.php';
