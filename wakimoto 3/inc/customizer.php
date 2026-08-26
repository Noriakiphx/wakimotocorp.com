<?php
/**
 * テーマカスタマイザー設定
 *
 * Customizer（外観 > カスタマイズ）から、ヒーロー文言・事業内容・
 * 連絡先・SNS などをコードを触らずに編集できるようにします。
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * チェックボックス用サニタイズ
 *
 * @param bool $checked 値。
 * @return bool
 */
function wakimoto_sanitize_checkbox( $checked ) {
	return ( ( isset( $checked ) && true === (bool) $checked ) ? true : false );
}

/**
 * テキスト/テキストエリア/URL/メール用の設定＋コントロールをまとめて追加するヘルパー
 *
 * @param WP_Customize_Manager $wp_customize Customizer オブジェクト。
 * @param string               $section      セクション ID。
 * @param string               $id           設定 ID。
 * @param string               $label        ラベル。
 * @param string               $default      既定値。
 * @param string               $type         text|textarea|url|email。
 * @param string               $description  説明文。
 */
function wakimoto_add_field( $wp_customize, $section, $id, $label, $default = '', $type = 'text', $description = '' ) {
	$sanitize     = 'sanitize_text_field';
	$control_type = 'text';

	if ( 'textarea' === $type ) {
		$sanitize     = 'wp_kses_post';
		$control_type = 'textarea';
	} elseif ( 'url' === $type ) {
		$sanitize     = 'esc_url_raw';
		$control_type = 'url';
	} elseif ( 'email' === $type ) {
		$sanitize     = 'sanitize_email';
		$control_type = 'email';
	}

	$wp_customize->add_setting(
		$id,
		array(
			'default'           => $default,
			'sanitize_callback' => $sanitize,
			'transport'         => 'refresh',
		)
	);

	$wp_customize->add_control(
		$id,
		array(
			'label'       => $label,
			'section'     => $section,
			'type'        => $control_type,
			'description' => $description,
		)
	);
}

/**
 * チェックボックス（表示/非表示）の設定＋コントロールを追加するヘルパー
 */
function wakimoto_add_toggle( $wp_customize, $section, $id, $label, $default = true ) {
	$wp_customize->add_setting(
		$id,
		array(
			'default'           => $default,
			'sanitize_callback' => 'wakimoto_sanitize_checkbox',
			'transport'         => 'refresh',
		)
	);
	$wp_customize->add_control(
		$id,
		array(
			'label'   => $label,
			'section' => $section,
			'type'    => 'checkbox',
		)
	);
}

/**
 * Customizer 設定の登録
 *
 * @param WP_Customize_Manager $wp_customize Customizer オブジェクト。
 */
function wakimoto_customize_register( $wp_customize ) {

	$wp_customize->get_setting( 'blogname' )->transport         = 'refresh';
	$wp_customize->get_setting( 'blogdescription' )->transport  = 'refresh';

	/* =========================================================
	 * パネル：サイト設定
	 * ========================================================= */
	$wp_customize->add_panel(
		'wakimoto_panel',
		array(
			'title'    => __( '脇本商会サイト設定', 'wakimoto' ),
			'priority' => 20,
		)
	);

	/* ---------------------------------------------------------
	 * ヘッダー
	 * --------------------------------------------------------- */
	$wp_customize->add_section(
		'wakimoto_header',
		array(
			'title' => __( 'ヘッダー', 'wakimoto' ),
			'panel' => 'wakimoto_panel',
		)
	);
	wakimoto_add_field( $wp_customize, 'wakimoto_header', 'wakimoto_header_phone', __( '電話番号', 'wakimoto' ), '0495-37-4806' );
	wakimoto_add_field( $wp_customize, 'wakimoto_header', 'wakimoto_header_cta_label', __( 'CTAボタンの文言', 'wakimoto' ), 'お問い合わせ' );
	wakimoto_add_field( $wp_customize, 'wakimoto_header', 'wakimoto_header_cta_url', __( 'CTAボタンのリンク先', 'wakimoto' ), '/contact/', 'url' );

	/* ---------------------------------------------------------
	 * ヒーロー
	 * --------------------------------------------------------- */
	$wp_customize->add_section(
		'wakimoto_hero',
		array(
			'title' => __( 'トップ：ヒーロー', 'wakimoto' ),
			'panel' => 'wakimoto_panel',
		)
	);
	wakimoto_add_field( $wp_customize, 'wakimoto_hero', 'wakimoto_hero_eyebrow', __( 'アイブロウ（英字ラベル）', 'wakimoto' ), 'PRO AUDIO SYSTEMS INTEGRATOR' );
	wakimoto_add_field( $wp_customize, 'wakimoto_hero', 'wakimoto_hero_heading', __( '見出し', 'wakimoto' ), "イベントの現場に、\n確かな技術と機材を。", 'textarea', __( '改行はそのまま反映されます。', 'wakimoto' ) );
	wakimoto_add_field( $wp_customize, 'wakimoto_hero', 'wakimoto_hero_subtext', __( '本文', 'wakimoto' ), "コンサート音響のオペレーションから、設備管理、機器導入のコンサルティング、機材レンタルまで。\nライブ・イベントと常設設備の両面で、プロフェッショナル・オーディオの現場を支えます。", 'textarea', __( '改行はそのまま反映されます。', 'wakimoto' ) );
	wakimoto_add_field( $wp_customize, 'wakimoto_hero', 'wakimoto_hero_primary_label', __( '主ボタンの文言', 'wakimoto' ), '事業を見る' );
	wakimoto_add_field( $wp_customize, 'wakimoto_hero', 'wakimoto_hero_primary_url', __( '主ボタンのリンク先', 'wakimoto' ), '#business', 'url' );
	wakimoto_add_field( $wp_customize, 'wakimoto_hero', 'wakimoto_hero_secondary_label', __( '副ボタンの文言', 'wakimoto' ), 'お問い合わせ' );
	wakimoto_add_field( $wp_customize, 'wakimoto_hero', 'wakimoto_hero_secondary_url', __( '副ボタンのリンク先', 'wakimoto' ), '/contact/', 'url' );

	/* ---------------------------------------------------------
	 * 事業内容（4領域・写真付き）
	 * --------------------------------------------------------- */
	$wp_customize->add_section(
		'wakimoto_business',
		array(
			'title' => __( 'トップ：事業内容（6領域）', 'wakimoto' ),
			'panel' => 'wakimoto_panel',
		)
	);
	wakimoto_add_field( $wp_customize, 'wakimoto_business', 'wakimoto_business_title', __( 'セクション見出し', 'wakimoto' ), '事業内容' );

	$business_defaults = array(
		1 => array(
			'title' => 'コンサートオペレーション',
			'desc'  => 'ライブ・コンサート・イベントの音響を、システム設計から本番のオペレーションまで一貫して担当します。',
			'url'   => '',
			'label' => '',
		),
		2 => array(
			'title' => '製品販売　正規販売店',
			'desc'  => '音響・映像・舞台照明機器の正規輸入販売店として、国内向けに製品を販売。オンラインストアでもご購入いただけます。',
			'url'   => '',
			'label' => 'オンラインストアへ',
		),
		3 => array(
			'title' => '輸入代理事業',
			'desc'  => 'DAS Audio 日本総代理店として、海外メーカー製品の輸入・代理店事業を行っています。詳細な取扱製品はお問い合わせください。',
			'url'   => '',
			'label' => '取扱ブランドを見る',
		),
		4 => array(
			'title' => '設備管理',
			'desc'  => 'ホールや施設の音響設備の保守・点検・運用管理。常設システムの安定稼働を支えます。',
			'url'   => '',
			'label' => '',
		),
		5 => array(
			'title' => '機器導入コンサルティング',
			'desc'  => '用途・規模・予算に応じた最適な機器の選定・導入を、仕様策定から調整まで一貫してサポートします。',
			'url'   => '',
			'label' => '',
		),
		6 => array(
			'title' => '機材レンタル',
			'desc'  => '音響・照明機材のレンタル。イベントの規模に合わせて、必要な機材を柔軟にご用意します。',
			'url'   => 'https://rental.wakimotocorp.com',
			'label' => 'レンタルサイトへ',
		),
	);

	foreach ( $business_defaults as $i => $d ) {
		wakimoto_add_field( $wp_customize, 'wakimoto_business', "wakimoto_biz{$i}_title", sprintf( __( '事業%d：タイトル', 'wakimoto' ), $i ), $d['title'] );
		wakimoto_add_field( $wp_customize, 'wakimoto_business', "wakimoto_biz{$i}_desc", sprintf( __( '事業%d：説明', 'wakimoto' ), $i ), $d['desc'], 'textarea' );

		$wp_customize->add_setting(
			"wakimoto_biz{$i}_image",
			array(
				'default'           => '',
				'sanitize_callback' => 'esc_url_raw',
				'transport'         => 'refresh',
			)
		);
		$wp_customize->add_control(
			new WP_Customize_Image_Control(
				$wp_customize,
				"wakimoto_biz{$i}_image",
				array(
					/* translators: %d: 事業番号 */
					'label'   => sprintf( __( '事業%d：写真', 'wakimoto' ), $i ),
					'section' => 'wakimoto_business',
				)
			)
		);

		wakimoto_add_field( $wp_customize, 'wakimoto_business', "wakimoto_biz{$i}_url", sprintf( __( '事業%d：リンク先', 'wakimoto' ), $i ), $d['url'], 'url' );
		wakimoto_add_field( $wp_customize, 'wakimoto_business', "wakimoto_biz{$i}_label", sprintf( __( '事業%d：リンク文言', 'wakimoto' ), $i ), $d['label'] );
	}

	/* ---------------------------------------------------------
	 * ニュース／お知らせ
	 * --------------------------------------------------------- */
	$wp_customize->add_section(
		'wakimoto_news',
		array(
			'title' => __( 'トップ：お知らせ', 'wakimoto' ),
			'panel' => 'wakimoto_panel',
		)
	);
	wakimoto_add_toggle( $wp_customize, 'wakimoto_news', 'wakimoto_news_enable', __( 'お知らせセクションを表示する', 'wakimoto' ), true );
	wakimoto_add_field( $wp_customize, 'wakimoto_news', 'wakimoto_news_title', __( 'セクション見出し', 'wakimoto' ), 'お知らせ' );

	$wp_customize->add_setting(
		'wakimoto_news_count',
		array(
			'default'           => 3,
			'sanitize_callback' => 'absint',
			'transport'         => 'refresh',
		)
	);
	$wp_customize->add_control(
		'wakimoto_news_count',
		array(
			'label'       => __( '表示件数', 'wakimoto' ),
			'section'     => 'wakimoto_news',
			'type'        => 'number',
			'input_attrs' => array(
				'min'  => 1,
				'max'  => 12,
				'step' => 1,
			),
		)
	);

	/* ---------------------------------------------------------
	 * お問い合わせ CTA
	 * --------------------------------------------------------- */
	$wp_customize->add_section(
		'wakimoto_contact',
		array(
			'title' => __( 'トップ：お問い合わせ CTA', 'wakimoto' ),
			'panel' => 'wakimoto_panel',
		)
	);
	wakimoto_add_field( $wp_customize, 'wakimoto_contact', 'wakimoto_contact_title', __( '見出し', 'wakimoto' ), 'プロジェクトのご相談を承ります' );
	wakimoto_add_field( $wp_customize, 'wakimoto_contact', 'wakimoto_contact_text', __( '本文', 'wakimoto' ), 'イベント音響、機材導入、海外ブランドの取り扱いなど、まずはお気軽にお問い合わせください。', 'textarea' );
	wakimoto_add_field( $wp_customize, 'wakimoto_contact', 'wakimoto_contact_label', __( 'ボタンの文言', 'wakimoto' ), 'お問い合わせフォームへ' );
	wakimoto_add_field( $wp_customize, 'wakimoto_contact', 'wakimoto_contact_url', __( 'ボタンのリンク先', 'wakimoto' ), '/contact/', 'url' );

	/* ---------------------------------------------------------
	 * フッター・会社情報
	 * --------------------------------------------------------- */
	$wp_customize->add_section(
		'wakimoto_footer',
		array(
			'title' => __( 'フッター・会社情報', 'wakimoto' ),
			'panel' => 'wakimoto_panel',
		)
	);
	wakimoto_add_field( $wp_customize, 'wakimoto_footer', 'wakimoto_company_name', __( '会社名', 'wakimoto' ), '脇本商会 / SoundAssist' );
	wakimoto_add_field( $wp_customize, 'wakimoto_footer', 'wakimoto_company_tagline', __( 'フッターの一言', 'wakimoto' ), '機材レンタル・映像制作&広告・輸入代理&正規代理店' );
	wakimoto_add_field( $wp_customize, 'wakimoto_footer', 'wakimoto_company_address', __( '住所', 'wakimoto' ), '〒367-0041 埼玉県本庄市駅南2-1-25 ふらわあビル3-A', 'textarea' );
	wakimoto_add_field( $wp_customize, 'wakimoto_footer', 'wakimoto_company_phone', __( '電話番号', 'wakimoto' ), '0495-37-4806' );
	wakimoto_add_field( $wp_customize, 'wakimoto_footer', 'wakimoto_company_email', __( 'メールアドレス', 'wakimoto' ), 'info@wakimotocorp.com', 'email' );
	wakimoto_add_field( $wp_customize, 'wakimoto_footer', 'wakimoto_copyright', __( 'コピーライト表記', 'wakimoto' ), '脇本商会' );

	// SNS
	wakimoto_add_field( $wp_customize, 'wakimoto_footer', 'wakimoto_social_x', __( 'X（旧Twitter）URL', 'wakimoto' ), '', 'url' );
	wakimoto_add_field( $wp_customize, 'wakimoto_footer', 'wakimoto_social_facebook', __( 'Facebook URL', 'wakimoto' ), '', 'url' );
	wakimoto_add_field( $wp_customize, 'wakimoto_footer', 'wakimoto_social_instagram', __( 'Instagram URL', 'wakimoto' ), '', 'url' );
	wakimoto_add_field( $wp_customize, 'wakimoto_footer', 'wakimoto_social_youtube', __( 'YouTube URL', 'wakimoto' ), '', 'url' );
	wakimoto_add_field( $wp_customize, 'wakimoto_footer', 'wakimoto_social_line', __( 'LINE URL', 'wakimoto' ), '', 'url' );
}
add_action( 'customize_register', 'wakimoto_customize_register' );
