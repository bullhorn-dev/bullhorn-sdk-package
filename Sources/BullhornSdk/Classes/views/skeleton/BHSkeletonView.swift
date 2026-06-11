import UIKit

// MARK: - Skeleton vew

final class BHSkeletonView: UIView {

    enum Row {
        case spacing(CGFloat)
        case sectionTitle
        /// Generic full-width rounded card.
        case banner(height: CGFloat, corner: CGFloat)
        /// Home channels strip (pills).
        case channelsStrip
        /// Radio streams strip
        case streamsStrip
        /// Radio streams card (home / radio). `laterStreams` adds the lower
        /// mini-carousel as on the Radio screen.
        case radioCard(laterStreams: Bool)
        /// Users carousel: rounded-square cover + name + category, matching
        /// BHUserCarouselCell. Sized via Constants.
        case usersCarousel(items: Int)
        /// Posts carousel (scheduled/live): rounded cards sized via Constants.
        case postsCarousel(items: Int)
        /// Featured posts paged carousel — one full-width card.
        case pagedBanner
        /// 3-column user grid (home/explore body).
        case grid(columns: Int, rows: Int)
        /// Vertical episode list matching BHPostCarouselCell
        /// (80pt thumb + title + description).
        case episodeList(count: Int)
        /// Vertical episode list matching BHPostCarouselCell
        /// (80pt thumb + title + description).
        case podcastList(count: Int)
        /// Vertical episode list matching BHPostCarouselCell
        /// (80pt thumb + title + description).
        case radioList(count: Int)
        /// Left-aligned profile row: avatar + text lines + optional trailing
        /// pill. Used by user/post detail headers.
        case profileRow(avatarSize: CGFloat, avatarCorner: CGFloat)
        /// Full-width rounded search field.
        case searchBar
        /// Centered block (artwork / title line).
        case centered(size: CGSize, corner: CGFloat)
        /// Button-shaped block.
        case pill(width: CGFloat, height: CGFloat, centered: Bool)
        /// Centered row of circles (e.g. share/like/download).
        case circleRow(diameters: [CGFloat])
        /// Paragraph of text lines; the last line is shortened.
        case paragraph(lines: Int)
    }

    private let stack = UIStackView()
    private var blocks: [BHShimmerBlock] = []

    private let pad = Constants.paddingHorizontal
    private let padV = Constants.paddingVertical

    // MARK: - Init

    init(rows: [Row]) {
        super.init(frame: .zero)
        backgroundColor = .primaryBackground()
        /// A skeleton overlay represents the "above the fold" area: its content
        /// can be taller than the visible region, so we let the stack grow to
        /// its intrinsic height and clip the overflow instead of forcing it to
        /// fit (which over-constrains the layout and breaks child constraints).
        clipsToBounds = true

        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = Constants.paddingVertical / 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            /// no bottom pin on purpose — see clipsToBounds note above
        ])

        rows.forEach { stack.addArrangedSubview(view(for: $0)) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Animation

    func start() { blocks.forEach { $0.startAnimating() } }
    func stop() { blocks.forEach { $0.stopAnimating() } }

    // MARK: - Presentation

    @discardableResult
    static func present(over container: UIView, rows: [Row], topInset: CGFloat = 0) -> BHSkeletonView {
        let skeleton = BHSkeletonView(rows: rows)
        skeleton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(skeleton)

        NSLayoutConstraint.activate([
            skeleton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            skeleton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            skeleton.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: topInset),
            skeleton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        skeleton.start()
        return skeleton
    }

    func dismiss(animated: Bool = true) {
        stop()
        guard animated else { removeFromSuperview(); return }
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    // MARK: - Block factory

    private func block(corner: CGFloat) -> BHShimmerBlock {
        let b = BHShimmerBlock()
        b.layer.cornerRadius = corner
        b.translatesAutoresizingMaskIntoConstraints = false
        blocks.append(b)
        return b
    }

    /// Vertical list with the cells' 16pt horizontal inset and a 16pt gap
    /// (matching the 8pt top + 8pt bottom card insets between table cells).
    private func makeListStack() -> UIStackView {
        let list = UIStackView()
        list.axis = .vertical
        list.alignment = .fill
        list.spacing = 16
        list.isLayoutMarginsRelativeArrangement = true
        list.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        list.translatesAutoresizingMaskIntoConstraints = false
        return list
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.layer.cornerRadius = 8
        card.backgroundColor = .cardBackground()
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }

    /// A leading-aligned column of `count` text lines; the last one is
    /// shortened to read like a paragraph. Width tracks the returned stack.
    private func linesBlock(count: Int, lineHeight: CGFloat, lastMultiplier: CGFloat) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        for i in 0..<max(count, 1) {
            let line = block(corner: 4)
            stack.addArrangedSubview(line)
            let isLast = (i == count - 1)
            line.heightAnchor.constraint(equalToConstant: lineHeight).isActive = true
            line.widthAnchor.constraint(equalTo: stack.widthAnchor,
                                        multiplier: (isLast && count > 1) ? lastMultiplier : 1.0).isActive = true
        }
        return stack
    }

    // MARK: - Row dispatch

    private func view(for row: Row) -> UIView {
        switch row {
        case let .spacing(value):
            let v = UIView()
            v.heightAnchor.constraint(equalToConstant: value).isActive = true
            return v
        case .sectionTitle:           return sectionTitleView()
        case let .banner(h, c):       return bannerView(height: h, corner: c)
        case .channelsStrip:          return channelsStripView()
        case .streamsStrip:           return streamsView(columns: 3, rows: 1)
        case let .radioCard(later):   return radioCardView(laterStreams: later)
        case let .usersCarousel(n):   return usersCarouselView(items: n)
        case let .postsCarousel(n):   return postsCarouselView(items: n)
        case .pagedBanner:            return bannerView(height: Constants.pagedCarouselHeight, corner: 12, inset: true)
        case let .grid(cols, rows):   return gridView(columns: cols, rows: rows)
        case let .episodeList(n):     return episodeListView(count: n)
        case let .podcastList(n):     return podcastListView(count: n)
        case let .radioList(n):       return radioListView(count: n)
        case let .profileRow(a, ac):  return profileRowView(avatarSize: a, avatarCorner: ac)
        case .searchBar:              return bannerView(height: 40, corner: 20, inset: true)
        case let .centered(size, c):  return centeredView(size: size, corner: c)
        case let .pill(w, h, c):      return pillView(width: w, height: h, centered: c)
        case let .circleRow(d):       return circleRowView(diameters: d)
        case let .paragraph(n):       return paragraphView(lines: n)
        }
    }

    // MARK: - Builders

    private func sectionTitleView() -> UIView {
        let container = UIView()
        container.heightAnchor.constraint(equalToConstant: Constants.panelHeight).isActive = true
        let b = block(corner: 4)
        container.addSubview(b)
        NSLayoutConstraint.activate([
            b.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: pad),
            b.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            b.heightAnchor.constraint(equalToConstant: 18),
            b.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.4),
        ])
        return container
    }

    private func bannerView(height: CGFloat, corner: CGFloat, inset: Bool = true) -> UIView {
        let container = UIView()
        let b = block(corner: corner)
        container.addSubview(b)
        let h: CGFloat = inset ? pad : 0
        NSLayoutConstraint.activate([
            b.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: h),
            b.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -h),
            b.topAnchor.constraint(equalTo: container.topAnchor),
            b.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            b.heightAnchor.constraint(equalToConstant: height),
        ])
        return container
    }

    private func channelsStripView() -> UIView {
        let container = UIView()
        container.clipsToBounds = true
        container.heightAnchor.constraint(equalToConstant: 56).isActive = true   // BHChannelsView default

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)

        let widths: [CGFloat] = [64, 92, 72, 104, 80, 96]
        for w in widths {
            let pill = block(corner: 16)
            row.addArrangedSubview(pill)
            NSLayoutConstraint.activate([
                pill.heightAnchor.constraint(equalToConstant: 32),
                pill.widthAnchor.constraint(equalToConstant: w),
            ])
        }
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: pad),
            row.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    private func radioCardView(laterStreams: Bool) -> UIView {
        let container = UIView()
        let spacing: CGFloat = 12   // BHRadioStreamsView.spacingHeight

        let card = UIView()
        card.layer.cornerRadius = 8
        card.backgroundColor = .cardBackground()
        card.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(card)

        let content = UIStackView()
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = spacing
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)

        let imageHeight = Constants.radioAspectRatio * (UIScreen.main.bounds.width - 4 * pad)
        let image = block(corner: 6)
        let title = block(corner: 4)
        content.addArrangedSubview(image)
        content.addArrangedSubview(title)
        image.heightAnchor.constraint(equalToConstant: imageHeight).isActive = true
        title.heightAnchor.constraint(equalToConstant: 16).isActive = true

        if laterStreams {
            let strip = streamsView(columns: 3, rows: 1)
            content.addArrangedSubview(strip)
//            strip.heightAnchor.constraint(equalToConstant: Constants.postsCarouselHeight).isActive = true
        }

        let play = block(corner: 24)
        content.addArrangedSubview(play)
        play.heightAnchor.constraint(equalToConstant: 48).isActive = true   // playBtnHeight

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            card.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
            card.topAnchor.constraint(equalTo: container.topAnchor, constant: 0),
            card.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: pad),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -pad),
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 0),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: 0),
        ])
        return container
    }

    private func usersCarouselView(items: Int) -> UIView {
        let container = UIView()
        container.clipsToBounds = true
        container.heightAnchor.constraint(equalToConstant: Constants.pagedCarouselHeight).isActive = true

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)

        let side = Constants.userProfileIconSize
        for _ in 0..<items {
            let card = UIStackView()
            card.axis = .vertical
            card.alignment = .leading
            card.spacing = 3

            let cover = block(corner: 8)
            let name = block(corner: 4)
            let category = block(corner: 4)
            card.addArrangedSubview(cover)
            card.addArrangedSubview(name)
            card.addArrangedSubview(category)

            NSLayoutConstraint.activate([
                cover.widthAnchor.constraint(equalToConstant: side),
                cover.heightAnchor.constraint(equalToConstant: side),
                name.heightAnchor.constraint(equalToConstant: 14),
                name.widthAnchor.constraint(equalTo: cover.widthAnchor, multiplier: 0.9),
                category.heightAnchor.constraint(equalToConstant: 10),
                category.widthAnchor.constraint(equalTo: cover.widthAnchor, multiplier: 0.6),
            ])
            row.addArrangedSubview(card)
        }
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: pad),
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 3),
        ])
        return container
    }

    private func postsCarouselView(items: Int) -> UIView {
        let container = UIView()
        container.clipsToBounds = true
        let h = Constants.postsCarouselHeight
        container.heightAnchor.constraint(equalToConstant: h).isActive = true

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)

        for _ in 0..<items {
            let card = block(corner: 8)
            row.addArrangedSubview(card)
            NSLayoutConstraint.activate([
                card.widthAnchor.constraint(equalToConstant: Constants.userProfileIconSize),
                card.heightAnchor.constraint(equalToConstant: h - padV),
            ])
        }
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: pad),
            row.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    private func gridView(columns: Int, rows: Int) -> UIView {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.alignment = .fill
        grid.spacing = Constants.itemSpacing
        grid.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: pad),
            grid.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -pad),
            grid.topAnchor.constraint(equalTo: container.topAnchor),
            grid.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        for _ in 0..<rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.alignment = .top
            rowStack.distribution = .fillEqually
            rowStack.spacing = Constants.itemSpacing

            for _ in 0..<columns {
                let cell = UIStackView()
                cell.axis = .vertical
                cell.alignment = .leading
                cell.spacing = 6

                let square = block(corner: 8)
                let line = block(corner: 4)
                cell.addArrangedSubview(square)
                cell.addArrangedSubview(line)
                NSLayoutConstraint.activate([
                    square.widthAnchor.constraint(equalTo: cell.widthAnchor),
                    square.heightAnchor.constraint(equalTo: square.widthAnchor),
                    line.heightAnchor.constraint(equalToConstant: 12),
                    line.widthAnchor.constraint(equalTo: cell.widthAnchor, multiplier: 0.8),
                ])
                rowStack.addArrangedSubview(cell)
            }
            grid.addArrangedSubview(rowStack)
        }
        return container
    }
    
    private func streamsView(columns: Int, rows: Int) -> UIView {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.alignment = .fill
        grid.spacing = Constants.itemSpacing
        grid.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            grid.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
            grid.topAnchor.constraint(equalTo: container.topAnchor),
            grid.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        for _ in 0..<rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.alignment = .top
            rowStack.distribution = .fillEqually
            rowStack.spacing = Constants.itemSpacing

            for _ in 0..<columns {
                let cell = UIStackView()
                cell.axis = .vertical
                cell.alignment = .leading
                cell.spacing = 6

                let square = block(corner: 8)
                let line = block(corner: 4)
                cell.addArrangedSubview(square)
                cell.addArrangedSubview(line)
                NSLayoutConstraint.activate([
                    square.widthAnchor.constraint(equalTo: cell.widthAnchor),
                    square.heightAnchor.constraint(equalToConstant: 64),
                    line.heightAnchor.constraint(equalToConstant: 12),
                    line.widthAnchor.constraint(equalTo: cell.widthAnchor, multiplier: 0.8),
                ])
                rowStack.addArrangedSubview(cell)
            }
            grid.addArrangedSubview(rowStack)
        }
        return container
    }

    /// Mirrors `BHPostCell`: card (inset 16) with a top row (52pt cover +
    /// title + 40pt play), a 3-line description, a row of 36pt action buttons
    /// and a date/duration footer.
    private func episodeListView(count: Int) -> UIView {
        let list = makeListStack()

        for _ in 0..<count {
            let card = makeCard()

            let content = UIStackView()
            content.axis = .vertical
            content.alignment = .fill
            content.spacing = 8
            content.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(content)

            // 1. top row: cover 52 + title + play 40
            let topRow = UIView()
            let cover = block(corner: 8)
            let title = block(corner: 4)
            let play = block(corner: 20)
            topRow.addSubview(cover)
            topRow.addSubview(title)
            topRow.addSubview(play)
            NSLayoutConstraint.activate([
                topRow.heightAnchor.constraint(equalToConstant: 60),
                cover.leadingAnchor.constraint(equalTo: topRow.leadingAnchor),
                cover.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),
                cover.widthAnchor.constraint(equalToConstant: 52),
                cover.heightAnchor.constraint(equalToConstant: 52),
                play.trailingAnchor.constraint(equalTo: topRow.trailingAnchor),
                play.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),
                play.widthAnchor.constraint(equalToConstant: 40),
                play.heightAnchor.constraint(equalToConstant: 40),
                title.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 12),
                title.trailingAnchor.constraint(equalTo: play.leadingAnchor, constant: -12),
                title.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),
                title.heightAnchor.constraint(equalToConstant: 16),
            ])
            content.addArrangedSubview(topRow)

            // 2. description (3 lines, last shortened)
            content.addArrangedSubview(linesBlock(count: 3, lineHeight: 12, lastMultiplier: 0.7))

            // 3. action buttons (like / share / download / options) — 36pt
            let actions = UIView()
            let circles = UIStackView()
            circles.axis = .horizontal
            circles.spacing = 8
            circles.translatesAutoresizingMaskIntoConstraints = false
            actions.addSubview(circles)
            for _ in 0..<4 {
                let c = block(corner: 18)
                circles.addArrangedSubview(c)
                c.widthAnchor.constraint(equalToConstant: 36).isActive = true
                c.heightAnchor.constraint(equalToConstant: 36).isActive = true
            }
            NSLayoutConstraint.activate([
                actions.heightAnchor.constraint(equalToConstant: 36),
                circles.leadingAnchor.constraint(equalTo: actions.leadingAnchor),
                circles.topAnchor.constraint(equalTo: actions.topAnchor),
                circles.bottomAnchor.constraint(equalTo: actions.bottomAnchor),
            ])
            content.addArrangedSubview(actions)

            // 4. footer: date (left) + duration (right)
            let footer = UIView()
            let date = block(corner: 4)
            let duration = block(corner: 4)
            footer.addSubview(date)
            footer.addSubview(duration)
            NSLayoutConstraint.activate([
                footer.heightAnchor.constraint(equalToConstant: 20),
                date.leadingAnchor.constraint(equalTo: footer.leadingAnchor),
                date.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
                date.heightAnchor.constraint(equalToConstant: 12),
                date.widthAnchor.constraint(equalTo: footer.widthAnchor, multiplier: 0.35),
                duration.trailingAnchor.constraint(equalTo: footer.trailingAnchor),
                duration.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
                duration.heightAnchor.constraint(equalToConstant: 12),
                duration.widthAnchor.constraint(equalToConstant: 56),
            ])
            content.addArrangedSubview(footer)

            NSLayoutConstraint.activate([
                content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                content.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
                content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            ])
            list.addArrangedSubview(card)
        }
        return list
    }

    /// Mirrors `BHUserCell`: card (inset 16, h≈104) with an 80pt cover on the
    /// left and a name (1 line) + bio (3 lines) column on the right.
    private func podcastListView(count: Int) -> UIView {
        let list = makeListStack()

        for _ in 0..<count {
            let card = makeCard()
            card.heightAnchor.constraint(equalToConstant: 104).isActive = true

            let cover = block(corner: 8)
            card.addSubview(cover)

            let column = UIStackView()
            column.axis = .vertical
            column.alignment = .leading
            column.spacing = 6
            column.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(column)

            let name = block(corner: 4)
            let bio1 = block(corner: 4)
            let bio2 = block(corner: 4)
            let bio3 = block(corner: 4)
            [name, bio1, bio2, bio3].forEach { column.addArrangedSubview($0) }

            NSLayoutConstraint.activate([
                cover.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                cover.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                cover.widthAnchor.constraint(equalToConstant: 80),
                cover.heightAnchor.constraint(equalToConstant: 80),

                column.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 16),
                column.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                column.centerYAnchor.constraint(equalTo: card.centerYAnchor),

                name.heightAnchor.constraint(equalToConstant: 16),
                name.widthAnchor.constraint(equalTo: column.widthAnchor, multiplier: 0.7),
                bio1.heightAnchor.constraint(equalToConstant: 11),
                bio1.widthAnchor.constraint(equalTo: column.widthAnchor),
                bio2.heightAnchor.constraint(equalToConstant: 11),
                bio2.widthAnchor.constraint(equalTo: column.widthAnchor),
                bio3.heightAnchor.constraint(equalToConstant: 11),
                bio3.widthAnchor.constraint(equalTo: column.widthAnchor, multiplier: 0.5),
            ])
            list.addArrangedSubview(card)
        }
        return list
    }
    
    /// Mirrors `BHRadioCell`: an accent title line, then a card (h≈139) with a
    /// 160×107 (3:2) cover on the left and a stream-title (3 lines) + Listen
    /// button column on the right.
    private func radioListView(count: Int) -> UIView {
        let list = makeListStack()

        for _ in 0..<count {
            let row = UIView()

            let titleLine = block(corner: 4)
            row.addSubview(titleLine)

            let card = makeCard()
            row.addSubview(card)

            let cover = block(corner: 8)
            card.addSubview(cover)

            let column = UIStackView()
            column.axis = .vertical
            column.alignment = .leading
            column.spacing = 8
            column.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(column)

            let s1 = block(corner: 4)
            let s2 = block(corner: 4)
            let s3 = block(corner: 4)
            let listen = block(corner: 18)
            [s1, s2, s3, listen].forEach { column.addArrangedSubview($0) }

            NSLayoutConstraint.activate([
                titleLine.topAnchor.constraint(equalTo: row.topAnchor, constant: 8),
                titleLine.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                titleLine.heightAnchor.constraint(equalToConstant: 20),
                titleLine.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: 0.45),

                card.topAnchor.constraint(equalTo: titleLine.bottomAnchor, constant: 12),
                card.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                card.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                card.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -8),

                cover.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                cover.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                cover.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
                /// 3:2 cover that scales with available width; the right column
                /// is the same width (matches BHRadioCell's fillProportionally).
                cover.widthAnchor.constraint(equalTo: column.widthAnchor),
                cover.heightAnchor.constraint(equalTo: cover.widthAnchor, multiplier: 2.0 / 3.0),

                column.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 12),
                column.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                column.centerYAnchor.constraint(equalTo: cover.centerYAnchor),

                s1.heightAnchor.constraint(equalToConstant: 14),
                s1.widthAnchor.constraint(equalTo: column.widthAnchor),
                s2.heightAnchor.constraint(equalToConstant: 12),
                s2.widthAnchor.constraint(equalTo: column.widthAnchor),
                s3.heightAnchor.constraint(equalToConstant: 12),
                s3.widthAnchor.constraint(equalTo: column.widthAnchor, multiplier: 0.7),
                listen.heightAnchor.constraint(equalToConstant: 36),
                listen.widthAnchor.constraint(equalTo: column.widthAnchor),
            ])
            list.addArrangedSubview(row)
        }
        return list
    }
    
    private func profileRowView(avatarSize: CGFloat, avatarCorner: CGFloat) -> UIView {
        let container = UIView()

        let avatar = block(corner: avatarCorner)
        container.addSubview(avatar)
        
        let lines = UIStackView()
        lines.axis = .vertical
        lines.alignment = .leading
        lines.distribution = .equalSpacing
        lines.spacing = 8
        lines.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(lines)

        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: pad),
            avatar.topAnchor.constraint(equalTo: container.topAnchor, constant: padV),
            avatar.widthAnchor.constraint(equalToConstant: avatarSize),
            avatar.heightAnchor.constraint(equalToConstant: avatarSize),
            container.bottomAnchor.constraint(equalTo: avatar.bottomAnchor, constant: padV),
            lines.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            lines.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -pad),
            lines.topAnchor.constraint(equalTo: avatar.topAnchor),
            lines.bottomAnchor.constraint(equalTo: avatar.bottomAnchor),
            
        ])

        for i in 0..<3 {
            let line = block(corner: 4)
            lines.addArrangedSubview(line)
            line.heightAnchor.constraint(equalToConstant: i < 2 ? 16 : 12).isActive = true
            line.widthAnchor.constraint(equalTo: lines.widthAnchor, multiplier: i == 0 ? 1.0 : 0.6).isActive = true
        }
        
        let pill = block(corner: 18)
        lines.addArrangedSubview(pill)
        pill.bottomAnchor.constraint(equalTo: lines.bottomAnchor).isActive = true
        pill.widthAnchor.constraint(equalToConstant: 160).isActive = true
        pill.heightAnchor.constraint(equalToConstant: 36).isActive = true

        return container
    }

    private func centeredView(size: CGSize, corner: CGFloat) -> UIView {
        let container = UIView()
        let b = block(corner: corner)
        container.addSubview(b)

        let preferredWidth = b.widthAnchor.constraint(equalToConstant: size.width)
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            b.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            b.topAnchor.constraint(equalTo: container.topAnchor),
            b.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            b.heightAnchor.constraint(equalToConstant: size.height),
            preferredWidth,
            b.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor, constant: -2 * pad),
        ])
        return container
    }

    private func pillView(width: CGFloat, height: CGFloat, centered: Bool) -> UIView {
        let container = UIView()
        let b = block(corner: height / 2)
        container.addSubview(b)

        var constraints: [NSLayoutConstraint] = [
            b.topAnchor.constraint(equalTo: container.topAnchor),
            b.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            b.heightAnchor.constraint(equalToConstant: height),
            b.widthAnchor.constraint(equalToConstant: width),
        ]
        constraints.append(centered
            ? b.centerXAnchor.constraint(equalTo: container.centerXAnchor)
            : b.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: pad))
        NSLayoutConstraint.activate(constraints)
        return container
    }

    private func circleRowView(diameters: [CGFloat]) -> UIView {
        let container = UIView()
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 28
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)

        for d in diameters {
            let c = block(corner: d / 2)
            row.addArrangedSubview(c)
            NSLayoutConstraint.activate([
                c.widthAnchor.constraint(equalToConstant: d),
                c.heightAnchor.constraint(equalToConstant: d),
            ])
        }
        NSLayoutConstraint.activate([
            row.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    private func paragraphView(lines: Int) -> UIView {
        let count = max(lines, 1)
        let container = UIView()

        var previous: UIView?
        for i in 0..<count {
            let line = block(corner: 4)
            container.addSubview(line)

            let isLast = (i == count - 1)
            NSLayoutConstraint.activate([
                line.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: pad),
                line.heightAnchor.constraint(equalToConstant: 12),
                previous == nil
                    ? line.topAnchor.constraint(equalTo: container.topAnchor)
                    : line.topAnchor.constraint(equalTo: previous!.bottomAnchor, constant: 8),
            ])
            if isLast && count > 1 {
                line.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.5).isActive = true
            } else {
                line.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -pad).isActive = true
            }
            if isLast {
                line.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
            }
            previous = line
        }
        return container
    }
}

// MARK: - Presets

extension BHSkeletonView {

    static func home() -> [Row] {
        return [
            .spacing(Constants.paddingVertical),
            .radioCard(laterStreams: false),
            .sectionTitle,
            .usersCarousel(items: 6),
            .channelsStrip,
            .sectionTitle,
            .grid(columns: 3, rows: 2),
        ]
    }

    static func explore() -> [Row] {
        return [
            .spacing(Constants.paddingVertical),
            .searchBar,
            .sectionTitle,
            .usersCarousel(items: 6),
            .sectionTitle,
            .usersCarousel(items: 6),
            .sectionTitle,
            .podcastList(count: 1),
        ]
    }

    static func radio() -> [Row] {
        return [
            .spacing(Constants.paddingVertical),
            .radioCard(laterStreams: true),
            .radioList(count: 1),
        ]
    }

    static func category() -> [Row] {
        return [
            .sectionTitle,
            .grid(columns: 3, rows: 2),
            .sectionTitle,
            .episodeList(count: 3),
        ]
    }

    static func userDetails() -> [Row] {
        return [
            .profileRow(avatarSize: 120, avatarCorner: 8),
            .paragraph(lines: 4),
            .spacing(4),
            .pill(width: 120, height: 32, centered: false),
            .spacing(4),
            .searchBar,
            .spacing(8),
            .episodeList(count: 4),
        ]
    }

    static func postDetails() -> [Row] {
        return [
            .spacing(Constants.paddingVertical),
            .centered(size: CGSize(width: 140, height: 140), corner: 8),
            .spacing(8),
            .centered(size: CGSize(width: 320, height: 15), corner: 4),
            .centered(size: CGSize(width: 200, height: 15), corner: 4),
            .spacing(8),
            .centered(size: CGSize(width: 240, height: 18), corner: 4),
            .spacing(8),
            .pill(width: 200, height: 44, centered: true),
            .spacing(4),
            .circleRow(diameters: [36, 36, 36]),
            .spacing(8),
            .paragraph(lines: 4),
            .paragraph(lines: 3),
            .paragraph(lines: 5),
        ]
    }
    
    static func posts() -> [Row] {
        return [
            .spacing(Constants.paddingVertical),
            .episodeList(count: 3),
        ]
    }

    static func users() -> [Row] {
        return [
            .spacing(Constants.paddingVertical),
            .podcastList(count: 4),
        ]
    }
    
    static func notifications() -> [Row] {
        return [
            .sectionTitle,
            .grid(columns: 3, rows: 4),
        ]
    }
}



