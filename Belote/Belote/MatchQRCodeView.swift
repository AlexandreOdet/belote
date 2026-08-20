//
//  MatchQRCodeView.swift
//  Belote
//
//  Created by Alexandre Odet on 20/08/2026.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

#if os(macOS)
import AppKit
private typealias BelotePlatformImage = NSImage
#else
import UIKit
private typealias BelotePlatformImage = UIImage
#endif

struct MatchQRCodeView: View {
    let match: BeloteMatch
    let joinLinkService: any BeloteJoinLinkService
    @State private var qrImage: BelotePlatformImage?
    @State private var joinURLText = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if let qrImage {
                    platformImage(qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260, height: 260)
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if let errorMessage {
                    ContentUnavailableView("QR Code indisponible", systemImage: "qrcode", description: Text(errorMessage))
                }

                VStack(spacing: 6) {
                    Text(match.inviteCode)
                        .font(.system(.title, design: .rounded, weight: .bold))
                    Text(joinURLText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .padding()
            .navigationTitle("Rejoindre la partie")
            .onAppear(perform: generateQRCode)
        }
    }

    private func generateQRCode() {
        do {
            let url = try joinLinkService.makeJoinURL(inviteCode: match.inviteCode)
            joinURLText = url.absoluteString
            qrImage = Self.makeQRCodeImage(from: url.absoluteString)
            if qrImage == nil {
                errorMessage = "Impossible de creer l'image du QR Code."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func makeQRCodeImage(from payload: String) -> BelotePlatformImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

#if os(macOS)
        return NSImage(cgImage: cgImage, size: NSSize(width: scaledImage.extent.width, height: scaledImage.extent.height))
#else
        return UIImage(cgImage: cgImage)
#endif
    }

    @ViewBuilder
    private func platformImage(_ image: BelotePlatformImage) -> Image {
#if os(macOS)
        Image(nsImage: image)
#else
        Image(uiImage: image)
#endif
    }
}
