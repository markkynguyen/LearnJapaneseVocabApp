# Nana App

Ứng dụng học từ vựng tiếng Nhật dùng Flutter và Supabase. Supabase PostgreSQL
là nguồn dữ liệu duy nhất; ứng dụng không tạo SQLite/IndexedDB và cần Internet
để đọc hoặc ghi dữ liệu học.

## Cấu hình Supabase

1. Tạo project Supabase và bật Email/Password trong Authentication.
2. Cài Supabase CLI và Docker, sau đó chạy:

   ```powershell
   supabase link --project-ref <project-ref>
   supabase db push
   ```

3. Thêm redirect URL `nanaapp://auth-callback` trong Authentication > URL
   Configuration. Với web, thêm URL triển khai kèm `/auth-callback`.
4. Chạy ứng dụng bằng publishable key, tuyệt đối không dùng service-role key:

   ```powershell
   flutter run `
     --dart-define=SUPABASE_URL=https://<project>.supabase.co `
     --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
   ```

Schema, RLS và RPC nằm trong `supabase/migrations/`. Kiểm thử SQL bằng
`supabase test db` sau khi `supabase start`.

## Cấu hình đăng nhập Google

Ứng dụng dùng Supabase OAuth qua trình duyệt, không dùng package `google_sign_in` và
không cần thêm Google Client Secret vào Flutter hoặc Vercel.

1. Trong Google Cloud Console, cấu hình OAuth consent screen với tên và thông tin
   của Nana App.
2. Tạo OAuth Client ID loại **Web application**. Trong **Authorized redirect URIs**,
   chỉ thêm callback của Supabase:

   ```text
   https://<project-ref>.supabase.co/auth/v1/callback
   ```

   Không thêm `nanaapp://auth-callback` vào Google Cloud Console.
3. Trong Supabase Dashboard > Authentication > Providers > Google, bật provider
   rồi nhập Client ID và Client Secret vừa tạo. Giữ automatic identity linking để
   tài khoản Google có cùng email đã xác minh dùng lại đúng user và dữ liệu cũ.
4. Trong Supabase Dashboard > Authentication > URL Configuration, thêm vào danh
   sách Redirect URLs:

   - `nanaapp://auth-callback`
   - `https://<domain-vercel>/auth-callback`
   - callback của từng domain preview/staging được phép sử dụng

Google Client Secret, Google access token và Supabase `service_role` key không được
đưa vào source code, biến build Flutter hoặc Vercel.

Tài liệu tham khảo: [Google OAuth với Supabase](https://supabase.com/docs/guides/auth/social-login/auth-google)
và [Supabase identity linking](https://supabase.com/docs/guides/auth/auth-identity-linking).

## Chuyển dữ liệu từ bản SQLite cũ

Trước khi nâng cấp, export toàn bộ dữ liệu thành Excel từ bản cũ. Sau khi đăng
nhập vào bản cloud, dùng Cài đặt > Import Excel. Cột `last_review` giữ thời điểm
ôn gần nhất. Ứng dụng không tự động đọc hoặc upload database SQLite cũ.

## Kiểm tra

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build web
flutter build windows
```

Supabase Free có giới hạn tài nguyên và project không hoạt động có thể bị pause;
kiểm tra Dashboard trước khi chẩn đoán lỗi kết nối từ ứng dụng.

## Triển khai web lên Vercel

Repo có `vercel.json` và `scripts/vercel_build.sh` để Vercel tự cài đúng phiên
bản Flutter, build ứng dụng và phục vụ các route GoRouter theo kiểu SPA.

1. Import Git repository vào Vercel với Framework Preset là `Other`.
2. Giữ nguyên Build Command và Output Directory từ `vercel.json`.
3. Trong Project Settings > Environment Variables, thêm cho Production và
   Preview:

   - `SUPABASE_URL`: URL dạng `https://<project-ref>.supabase.co`.
   - `SUPABASE_PUBLISHABLE_KEY`: publishable key của cùng project.
   - `FLUTTER_VERSION`: không bắt buộc, mặc định là `3.44.2`.

4. Deploy, sau đó thêm các giá trị sau vào Supabase Authentication > URL
   Configuration:

   - Site URL: `https://<ten-project>.vercel.app`
   - Redirect URL: `https://<ten-project>.vercel.app/auth-callback`

Publishable key được nhúng vào ứng dụng web theo thiết kế của Supabase. Không
đặt `service_role` hoặc secret key trong biến môi trường dùng để build Flutter.
