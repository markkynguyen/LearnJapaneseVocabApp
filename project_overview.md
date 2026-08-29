# Tổng quan dự án Nana App (jvocab)

Nana App là một ứng dụng học từ vựng tiếng Nhật áp dụng phương pháp lặp lại ngắt quãng (Spaced Repetition).

## Công nghệ sử dụng (Tech Stack)
- **Frontend**: Flutter (Hỗ trợ đa nền tảng: Web, Windows, Android, iOS, MacOS, Linux).
- **Backend & Database**: Supabase (PostgreSQL).
- **State Management**: Riverpod (`flutter_riverpod`, `riverpod_generator`).
- **Routing**: GoRouter (`go_router`).
- **Authentication**: Supabase Auth (Hỗ trợ đăng nhập bằng Email/Password và Google OAuth qua trình duyệt).

## Tính năng & Đặc điểm nổi bật
- **Đồng bộ hóa đám mây**: Ứng dụng sử dụng hoàn toàn cơ sở dữ liệu trên cloud thông qua Supabase, yêu cầu có kết nối Internet để đọc/ghi dữ liệu (đã chuyển đổi từ việc dùng SQLite local).
- **Di chuyển dữ liệu**: Hỗ trợ tính năng Import từ file Excel để người dùng phiên bản cũ (dùng SQLite) có thể giữ lại tiến độ học tập (thời điểm ôn tập gần nhất).
- **Thông báo & Nhắc nhở**: Sử dụng `flutter_local_notifications` và `timezone` để lên lịch nhắc nhở học từ vựng.
- **Phát âm (Text-to-Speech)**: Tích hợp `flutter_tts` để hỗ trợ đọc từ vựng tiếng Nhật.
- **Xử lý file**: Dùng `excel` và `file_picker` cho các tác vụ liên quan đến nhập/xuất dữ liệu.

## Triển khai (Deployment)
- Phiên bản Web của ứng dụng được cấu hình sẵn để triển khai lên **Vercel** dưới dạng Single Page Application (SPA), tích hợp sẵn các script hỗ trợ quá trình build (`vercel.json`, `scripts/vercel_build.sh`).
- Cơ sở dữ liệu và Backend functions (Schema, RLS, RPC) được quản lý chặt chẽ thông qua Supabase CLI (`supabase/migrations/`).
