import SwiftUI
@preconcurrency import AVFoundation
import AppKit

/// Dynamic notch widget displaying a live camera mirror from the MacBook FaceTime HD camera.
public struct CameraMirrorWidgetView: View {
    @State private var isCameraActive: Bool = false

    public init() {}

    public var body: some View {
        HStack(spacing: 16) {
            // Camera Preview View
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                if isCameraActive {
                    CameraPreviewRepresentable()
                        .clipShape(Circle())
                        .frame(width: 56, height: 56)
                } else {
                    Image(systemName: "video.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }

                // Live Camera Indicator
                if isCameraActive {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .offset(x: 20, y: -20)
                }
            }

            // Description and Toggle Button
            VStack(alignment: .leading, spacing: 4) {
                Text("Notch Camera Mirror")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Text(isCameraActive ? "Camera is live" : "Quick glance before calls")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Button(isCameraActive ? "Stop Mirror" : "Start Mirror") {
                    withAnimation { isCameraActive.toggle() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(isCameraActive ? .red : .blue)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

/// AppKit bridge for live AVCaptureSession preview
public struct CameraPreviewRepresentable: NSViewRepresentable {
    public func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 56, height: 56))
        let session = AVCaptureSession()
        session.sessionPreset = .low

        if let device = AVCaptureDevice.default(for: .video),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer = previewLayer
            view.wantsLayer = true

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}
}
