<?php
/**
 * フロントページ（トップ）テンプレート
 *
 * 「設定 > 表示設定」でフロントページを「固定ページ」に設定すると、
 * その固定ページの本文より優先してこのテンプレートが使われます。
 *
 * @package Wakimoto
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

get_header();

/* ----- ヒーロー ----- */
$hero_eyebrow   = wakimoto_get_mod( 'wakimoto_hero_eyebrow' );
$hero_heading   = wakimoto_get_mod( 'wakimoto_hero_heading' );
$hero_subtext   = wakimoto_get_mod( 'wakimoto_hero_subtext' );
$hero_p_label   = wakimoto_get_mod( 'wakimoto_hero_primary_label' );
$hero_p_url     = wakimoto_get_mod( 'wakimoto_hero_primary_url' );
$hero_s_label   = wakimoto_get_mod( 'wakimoto_hero_secondary_label' );
$hero_s_url     = wakimoto_get_mod( 'wakimoto_hero_secondary_url' );
?>

<main id="primary" class="site-main front-page">

	<section class="hero" aria-labelledby="hero-heading">
		<div class="hero__bg" aria-hidden="true">
			<span class="hero__glow"></span>
			<span class="hero__grid"></span>
			<?php wakimoto_array_motif(); ?>
		</div>

		<div class="container hero__inner">
			<div class="hero__content">
				<?php if ( $hero_eyebrow ) : ?>
					<span class="hero__eyebrow"><?php echo esc_html( $hero_eyebrow ); ?></span>
				<?php endif; ?>

				<?php if ( $hero_heading ) : ?>
					<h1 id="hero-heading" class="hero__heading"><?php echo nl2br( esc_html( $hero_heading ) ); ?></h1>
				<?php endif; ?>

				<?php if ( $hero_subtext ) : ?>
					<p class="hero__subtext"><?php echo nl2br( esc_html( $hero_subtext ) ); ?></p>
				<?php endif; ?>

				<div class="hero__actions">
					<?php if ( $hero_p_label && $hero_p_url ) : ?>
						<a class="btn btn--accent" href="<?php echo esc_url( $hero_p_url ); ?>"><?php echo esc_html( $hero_p_label ); ?></a>
					<?php endif; ?>
					<?php if ( $hero_s_label && $hero_s_url ) : ?>
						<a class="btn btn--ghost" href="<?php echo esc_url( $hero_s_url ); ?>"><?php echo esc_html( $hero_s_label ); ?></a>
					<?php endif; ?>
				</div>
			</div>
		</section>

	<?php
	/* ----- 事業展開内容（6領域・写真付き） ----- */
	$biz_title = wakimoto_get_mod( 'wakimoto_business_title', '事業内容' );
	?>
	<section id="business" class="section business" aria-labelledby="business-title">
		<div class="container">
			<header class="section__head reveal" data-reveal>
				<?php wakimoto_eyebrow( '01', 'OUR BUSINESS' ); ?>
				<h2 id="business-title" class="section__title"><?php echo esc_html( $biz_title ); ?></h2>
			</header>

			<div class="business-grid">
				<?php for ( $i = 1; $i <= 6; $i++ ) : ?>
					<?php
					$b_title = wakimoto_get_mod( "wakimoto_biz{$i}_title" );
					$b_desc  = wakimoto_get_mod( "wakimoto_biz{$i}_desc" );
					$b_url   = wakimoto_get_mod( "wakimoto_biz{$i}_url" );
					$b_label = wakimoto_get_mod( "wakimoto_biz{$i}_label" );
					$b_image = wakimoto_get_mod( "wakimoto_biz{$i}_image" );
					if ( ! $b_title ) {
						continue;
					}
					?>
					<article class="biz-card reveal" data-reveal style="--reveal-delay: <?php echo esc_attr( $i * 70 ); ?>ms;">
						<div class="biz-card__media">
							<?php if ( $b_image ) : ?>
								<img src="<?php echo esc_url( $b_image ); ?>" alt="<?php echo esc_attr( $b_title ); ?>" loading="lazy" decoding="async">
							<?php else : ?>
								<span class="biz-card__ph" aria-hidden="true">
									<?php wakimoto_array_motif(); ?>
									<span class="screen-reader-text"><?php echo esc_html( $b_title ); ?></span>
								</span>
							<?php endif; ?>
							<span class="biz-card__no">0<?php echo (int) $i; ?></span>
						</div>
						<div class="biz-card__body">
							<h3 class="biz-card__title"><?php echo esc_html( $b_title ); ?></h3>
							<?php if ( $b_desc ) : ?>
								<p class="biz-card__desc"><?php echo esc_html( $b_desc ); ?></p>
							<?php endif; ?>
							<?php if ( $b_url && $b_label ) : ?>
								<a class="biz-card__link" href="<?php echo esc_url( $b_url ); ?>">
									<span><?php echo esc_html( $b_label ); ?></span>
									<svg viewBox="0 0 24 24" width="18" height="18" fill="none" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
								</a>
							<?php endif; ?>
						</div>
					</article>
				<?php endfor; ?>
			</div>
		</div>
	</section>

	<?php
	/* ----- お知らせ ----- */
	if ( wakimoto_get_mod( 'wakimoto_news_enable', true ) ) :
		$news_title = wakimoto_get_mod( 'wakimoto_news_title', 'お知らせ' );
		$news_count = (int) wakimoto_get_mod( 'wakimoto_news_count', 3 );
		$news_query = new WP_Query(
			array(
				'post_type'           => 'post',
				'posts_per_page'      => $news_count > 0 ? $news_count : 3,
				'ignore_sticky_posts' => true,
				'no_found_rows'       => true,
			)
		);
		if ( $news_query->have_posts() ) :
			?>
			<section class="section news" aria-labelledby="news-title">
				<div class="container">
					<header class="section__head section__head--row reveal" data-reveal>
						<div>
							<?php wakimoto_eyebrow( '02', 'NEWS' ); ?>
							<h2 id="news-title" class="section__title"><?php echo esc_html( $news_title ); ?></h2>
						</div>
						<a class="text-link" href="<?php echo esc_url( get_permalink( get_option( 'page_for_posts' ) ) ? get_permalink( get_option( 'page_for_posts' ) ) : home_url( '/?post_type=post' ) ); ?>">
							<span><?php esc_html_e( '一覧を見る', 'wakimoto' ); ?></span>
							<svg viewBox="0 0 24 24" width="16" height="16" fill="none" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
						</a>
					</header>

					<ul class="news-list">
						<?php
						while ( $news_query->have_posts() ) :
							$news_query->the_post();
							?>
							<li class="news-item reveal" data-reveal>
								<a href="<?php the_permalink(); ?>" class="news-item__link">
									<time class="news-item__date" datetime="<?php echo esc_attr( get_the_date( DATE_W3C ) ); ?>"><?php echo esc_html( get_the_date() ); ?></time>
									<?php
									$cats = get_the_category();
									if ( ! empty( $cats ) ) :
										?>
										<span class="news-item__cat"><?php echo esc_html( $cats[0]->name ); ?></span>
									<?php endif; ?>
									<span class="news-item__title"><?php the_title(); ?></span>
									<svg class="news-item__arrow" viewBox="0 0 24 24" width="16" height="16" fill="none" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
								</a>
							</li>
							<?php
						endwhile;
						?>
					</ul>
				</div>
			</section>
			<?php
		endif;
		wp_reset_postdata();
	endif;
	?>

	<?php
	/* ----- お問い合わせ CTA ----- */
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

</main><!-- #primary -->

<?php
get_footer();
