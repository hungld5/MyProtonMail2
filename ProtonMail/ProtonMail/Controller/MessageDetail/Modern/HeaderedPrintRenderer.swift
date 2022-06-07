//
//  HeaderedPrintRenderer.swift
//  Proton Mail - Created on 12/08/2019.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

class HeaderedPrintRenderer: UIPrintPageRenderer {
    var header: CustomViewPrintRenderer?
    var attachmentView: CustomViewPrintRenderer?

    class CustomViewPrintRenderer: UIPrintPageRenderer {
        private(set) var view: UIView
        private(set) var contentSize: CGSize
        private var image: UIImage?

        func updateImage(in rect: CGRect) {
            self.contentSize = rect.size

            UIGraphicsBeginImageContextWithOptions(rect.size, true, 0.0)
            defer { UIGraphicsEndImageContext() }

            guard let context = UIGraphicsGetCurrentContext() else {
                self.image = nil
                return
            }
            self.view.layer.render(in: context)
            self.image = UIGraphicsGetImageFromCurrentImageContext()
        }

        init(_ view: UIView) {
            self.view = view
            self.contentSize = view.bounds.size
        }

        override func drawContentForPage(at pageIndex: Int, in contentRect: CGRect) {
            super.drawContentForPage(at: pageIndex, in: contentRect)
            guard pageIndex == 0 else { return }
            if let _ = UIGraphicsGetCurrentContext() {
                self.image?.draw(in: contentRect)
            }
        }
    }

    override func drawContentForPage(at pageIndex: Int, in contentRect: CGRect) {
        guard pageIndex == 0,
              let headerHeight = self.header?.contentSize.height else {
            super.drawContentForPage(at: pageIndex, in: contentRect)
            return
        }

        let (shortRect, longRect) = contentRect.divided(atDistance: headerHeight, from: .minYEdge)
        self.header?.drawContentForPage(at: pageIndex, in: shortRect)

        if let attachmentHeight = self.attachmentView?.contentSize.height {
            let (shortRectB, longRectB) = longRect.divided(atDistance: attachmentHeight,
                                                           from: .minYEdge)
            self.attachmentView?.drawContentForPage(at: pageIndex, in: shortRectB)
            super.drawContentForPage(at: pageIndex, in: longRectB)
        } else {
            super.drawContentForPage(at: pageIndex, in: longRect)
        }
    }

    override func drawPrintFormatter(_ printFormatter: UIPrintFormatter, forPageAt pageIndex: Int) {
        guard pageIndex == 0 else {
            super.drawPrintFormatter(printFormatter, forPageAt: pageIndex)
            return
        }
        let headerHeight = self.header?.contentSize.height ?? 0
        let attachHeight = self.attachmentView?.contentSize.height ?? 0
        printFormatter.perPageContentInsets = UIEdgeInsets(top: (headerHeight + attachHeight) * 1.25, left: 0, bottom: 0, right: 0)
        super.drawPrintFormatter(printFormatter, forPageAt: pageIndex)
        printFormatter.perPageContentInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }
}

@objc protocol Printable {
    func printPageRenderer() -> UIPrintPageRenderer
    @objc optional func printingWillStart(renderer: UIPrintPageRenderer)
    @objc optional func printingDidFinish()
}
