import SwiftUI

struct DriveListView: View {
    @State private var files: [DriveFile] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var toast: ToastData?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ScrollView {
                        VStack(spacing: AppSpacing.md) {
                            ForEach(0..<5, id: \.self) { _ in
                                DriveFileRowSkeleton()
                            }
                        }
                        .padding(AppSpacing.lg)
                    }
                } else if let errorMessage, files.isEmpty {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: AppSpacing.iconXl))
                            .foregroundStyle(AppColor.warning)
                        Text("Couldn't load Drive files")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColor.textPrimary)
                        Text(errorMessage)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)

                        PrimaryButton(
                            title: "Try Again",
                            systemImage: "arrow.clockwise"
                        ) {
                            Task { await loadFiles() }
                        }
                    }
                    .padding(AppSpacing.lg)
                } else if files.isEmpty {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "folder")
                            .font(.system(size: AppSpacing.iconXl))
                            .foregroundStyle(AppColor.textSecondary)
                        Text("No Drive files yet")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColor.textPrimary)
                        Text("Files uploaded from InboxIQ will appear here")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .padding(AppSpacing.lg)
                } else {
                    List(files) { file in
                        DriveFileRow(file: file)
                            .onTapGesture {
                                openInDrive(file)
                            }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await loadFiles(showLoading: false)
                    }
                }
            }
            .navigationTitle("Drive Files")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await loadFiles() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .overlay(alignment: .top) {
                if let toast {
                    ToastView(text: toast.message, style: toast.style)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            .task {
                await loadFiles()
            }
        }
    }

    private func loadFiles(showLoading: Bool = true) async {
        guard !isLoading else { return }
        if showLoading {
            isLoading = true
        }
        errorMessage = nil

        defer { isLoading = false }

        do {
            files = try await DriveService.shared.listFiles()
        } catch let error as AppError {
            errorMessage = error.localizedDescription
            showToast(error.localizedDescription, style: .error)
        } catch {
            errorMessage = "Something went wrong. Please try again."
            showToast("Unable to load Drive files", style: .error)
        }
    }

    private func openInDrive(_ file: DriveFile) {
        guard let url = URL(string: file.webViewLink) else { return }
        UIApplication.shared.open(url)
    }

    private func showToast(_ message: String, style: ToastStyle) {
        toast = ToastData(message: message, style: style)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if toast?.message == message {
                toast = nil
            }
        }
    }
}

private struct DriveFileRowSkeleton: View {
    @State private var shimmerOffset: CGFloat = -120

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm)
                .fill(AppColor.backgroundSecondary)
                .frame(width: AppSpacing.iconLg, height: AppSpacing.iconLg)
                .overlay(shimmer)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm)
                    .fill(AppColor.backgroundSecondary)
                    .frame(height: 16)
                    .overlay(shimmer)
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm)
                    .fill(AppColor.backgroundSecondary)
                    .frame(width: 160, height: 12)
                    .overlay(shimmer)
            }

            Spacer()

            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm)
                .fill(AppColor.backgroundSecondary)
                .frame(width: 12, height: 12)
                .overlay(shimmer)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMd))
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                shimmerOffset = 220
            }
        }
    }

    private var shimmer: some View {
        LinearGradient(
            colors: [Color.clear, Color.white.opacity(0.35), Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
        .rotationEffect(.degrees(20))
        .offset(x: shimmerOffset)
        .blendMode(.screen)
        .clipped()
    }
}
