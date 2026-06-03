<?php
/**
 * Template Name: 業務内容（サービス詳細）
 *
 * 4つの業務（コンサートオペレーション／設備管理／機器導入コンサルティング／
 * 機材レンタル）を、写真付きで詳しく紹介するための固定ページテンプレートです。
 *
 * 使い方：
 *   1. 固定ページ「業務内容」を作成
 *   2. ページ属性 → テンプレートで「業務内容（サービス詳細）」を選択
 *   3.（任意）本文にリード文を書くと、各サービスの上に表示されます
 *   4. 各サービスの写真は「外観 → カスタマイズ → トップ：事業内容（6領域）」で
 *      設定した画像（事業1〜4の写真）をそのまま使用します
 *
 * 各サービスの詳細テキスト（リード文・対応内容）は、下記 $services 配列を
 * 編集することで変更できます。
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

get_header();

/**
 * サービス詳細の内容。
 * 'img_key' は Customizer の画像設定キー（トップの事業写真を共用）。
 */
$services = array(
	array(
		'no'       => '01',
		'title'    => 'コンサートオペレーション',
		'lead'     => 'ライブ・コンサート・イベントの音響を、システム設計から本番運用まで一貫して担当します。会場の規模や音響特性に合わせて最適なシステムプランを構築し、確かなオペレーションで本番を支えます。',
		'features' => array(
			'ラインアレイ／ポイントソースのシステム設計・音響シミュレーション',
			'FOH（客席）／モニターのミキシングオペレーション',
			'ワイヤレスマイクの周波数調整・電波運用管理',
			'デジタルミキサー・ステージ回線の設計と運用',
			'リハーサルから本番までの音響ディレクション',
		),
		'img_key'  => 'wakimoto_biz1_image',
	),
	array(
		'no'       => '02',
		'title'    => '設備管理',
		'lead'     => 'ホール・劇場・店舗などの常設音響設備を、安定して稼働させるための保守・点検・運用をサポートします。定期点検から不具合対応、システム更新の計画まで、設備のライフサイクル全体を支えます。',
		'features' => array(
			'音響・映像設備の定期点検とメンテナンス',
			'不具合の切り分け・修理対応',
			'システム更新・リプレースの計画立案',
			'操作マニュアルの整備とスタッフトレーニング',
			'ネットワークオーディオ（AoIP）の運用サポート',
		),
		'img_key'  => 'wakimoto_biz4_image',
	),
	array(
		'no'       => '03',
		'title'    => '機器導入コンサルティング',
		'lead'     => '用途・規模・予算に応じて、最適な機器構成をご提案します。要件のヒアリングから仕様策定・機器選定、設置・調整、運用開始まで一貫してサポートします。',
		'features' => array(
			'要件ヒアリングと現地調査',
			'システム仕様の策定・機器選定',
			'図面作成・配線設計',
			'設置・調整・音響チューニング',
			'導入後の運用サポート・保守のご提案',
		),
		'img_key'  => 'wakimoto_biz5_image',
	),
	array(
		'no'       => '04',
		'title'    => '機材レンタル',
		'lead'     => '音響・照明機材のレンタルに対応します。イベントの規模や内容に合わせて必要な機材を柔軟にご用意し、搬入・設置・撤収までサポートします。',
		'features' => array(
			'スピーカー・アンプ・ミキサーなどの音響機材',
			'ワイヤレスマイク・モニターシステム',
			'照明機材',
			'単品レンタルからシステム一式まで',
			'オンライン見積りに対応',
		),
		'img_key'  => 'wakimoto_biz6_image',
	),
);

while ( have_posts() ) :
	the_post();
	?>
	<main id="primary" class="site-main services-page">

		<header class="page-hero">
			<div class="page-hero__bg" aria-hidden="true"><span class="hero__grid"></span></div>
			<div class="container">
				<?php wakimoto_eyebrow( '—', 'SERVICES' ); ?>
				<h1 class="page-hero__title"><?php the_title(); ?></h1>
			</div>
		</header>

		<?php
		$wakimoto_intro = trim( get_the_content() );
		if ( '' !== $wakimoto_intro ) :
			?>
			<div class="container services-intro reveal" data-reveal>
				<div class="prose">
					<?php the_content(); ?>
				</div>
			</div>
		<?php endif; ?>

		<div class="container">
			<div class="service-list">
				<?php
				foreach ( $services as $idx => $s ) :
					$img = wakimoto_get_mod( $s['img_key'] );
					$rev = ( 1 === $idx % 2 ) ? ' service-row--rev' : '';
					?>
					<section class="service-row<?php echo esc_attr( $rev ); ?> reveal" data-reveal>
						<div class="service-row__media">
							<?php if ( $img ) : ?>
								<img src="<?php echo esc_url( $img ); ?>" alt="<?php echo esc_attr( $s['title'] ); ?>" loading="lazy" decoding="async">
							<?php else : ?>
								<span class="biz-card__ph" aria-hidden="true">
									<?php wakimoto_array_motif(); ?>
									<span class="biz-card__ph-label">PHOTO</span>
								</span>
							<?php endif; ?>
							<span class="service-row__no"><?php echo esc_html( $s['no'] ); ?></span>
						</div>

						<div class="service-row__body">
							<h2 class="service-row__title"><?php echo esc_html( $s['title'] ); ?></h2>
							<p class="service-row__lead"><?php echo esc_html( $s['lead'] ); ?></p>
							<?php if ( ! empty( $s['features'] ) ) : ?>
								<ul class="service-features">
									<?php foreach ( $s['features'] as $f ) : ?>
										<li><?php echo esc_html( $f ); ?></li>
									<?php endforeach; ?>
								</ul>
							<?php endif; ?>
						</div>
					</section>
				<?php endforeach; ?>
			</div>
		</div>

		<?php
		/* お問い合わせ CTA（トップと同じ Customizer 設定を共用） */
		$c_title = wakimoto_get_mod( 'wakimoto_contact_title' );
		$c_text  = wakimoto_get_mod( 'wakimoto_contact_text' );
		$c_label = wakimoto_get_mod( 'wakimoto_contact_label' );
		$c_url   = wakimoto_get_mod( 'wakimoto_contact_url' );
		if ( $c_title || $c_label ) :
			?>
			<section class="section cta" aria-labelledby="cta-title">
				<div class="container cta__inner reveal" data-reveal>
					<div class="cta__text">
						<?php if ( $c_title ) : ?>
							<h2 id="cta-title" class="cta__title"><?php echo esc_html( $c_title ); ?></h2>
						<?php endif; ?>
						<?php if ( $c_text ) : ?>
							<p class="cta__lead"><?php echo esc_html( $c_text ); ?></p>
						<?php endif; ?>
					</div>
					<?php if ( $c_label && $c_url ) : ?>
						<a class="btn btn--accent btn--lg" href="<?php echo esc_url( $c_url ); ?>"><?php echo esc_html( $c_label ); ?></a>
					<?php endif; ?>
				</div>
			</section>
		<?php endif; ?>

	</main>
	<?php
endwhile;

get_footer();
