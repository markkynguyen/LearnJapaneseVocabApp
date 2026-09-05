# Kanji & Bộ thủ — bàn giao triển khai

Mã nguồn nằm tại `D:\LearnJVocabApp`. Tính năng dùng Supabase, không thêm SQLite/Drift. Chưa áp dụng migration lên cloud và chưa phát hành ứng dụng.

## Phạm vi đã triển khai

- Pipeline tái lập: 214 bộ Khang Hy, 2.136 Jōyō, 7.820 quan hệ thành phần; lớp 1–6 hoặc 8 (Trung học), không có JLPT.
- Schema, RLS, RPC thống kê thủ công và RPC đọc snapshot nguyên tử, không bị giới hạn 1.000 hàng của PostgREST.
- Tab Hán tự, hai lưới theo tần suất, dialog Kanji/Bộ thủ liên kết chéo, phân trang chuỗi như `先生`, trạng thái chưa hỗ trợ.
- Phân tích từ Flashcard và kết quả tìm kiếm Trang chủ; không sửa SRS/từ vựng.
- KanjiVG CDN pin commit, cache bộ nhớ/lưu bền, từng nét tích lũy, phát/tạm dừng/vẽ lại, giảm chuyển động. SVG có transform không dùng được với bộ phát nét sẽ chuyển sang trình SVG tĩnh theo từng bước, đã lọc chỉ còn path/group. SVG hỏng hoàn toàn có thông báo lỗi và thử lại, không ngăn xem nghĩa/cách đọc.
- Attribution trong Cài đặt → Nguồn dữ liệu & giấy phép.

## Hợp đồng thống kê

`recalculate_user_kanji_and_radical_stats()` không nhận user ID từ client; chỉ dùng `auth.uid()` và chỉ đọc `vocabulary.kanji` của tài khoản đó, gồm cả bộ từ tạm dừng học.

- Mỗi lần xuất hiện được tính: `先生先生` cho 先=2, 生=2.
- Một bộ được tính một lần trên mỗi lần xuất hiện của Kanji chứa bộ đó: `森` cho 木=1, không phải 3. Các dạng của cùng bộ trong cùng Kanji cũng không nhân đôi số đếm.
- `total_vocab_scanned` là số dòng từ vựng của tài khoản đã duyệt, gồm trường Kanji null/rỗng. Null, khoảng trắng, kana, 々, emoji và variation selector không tạo số đếm Kanji.
- `unsupported_kanji_count` là số **ký tự CJK khác nhau** ngoài danh mục, không phải số lần xuất hiện. Xử lý Unicode scalar, gồm chữ ngoài BMP và Extension J của Unicode 17.
- Thêm/sửa/xóa từ không tính lại. Đọc màn hình, đổi tab, mở dialog và thử tải lại cũng không gọi RPC tính toán. Không khóa sau 10 ngày.
- Nút cập nhật gọi RPC rồi đọc lại cả overview/hai lưới. Advisory lock theo tài khoản và transaction ngăn kết quả ghi dở dang khi hai thiết bị cùng tính hoặc RPC lỗi.

## Sinh lại seed và duyệt dữ liệu

Chạy từ gốc repo, cần Python 3 (thư viện chuẩn):

```powershell
python tool/kanji/build_seed.py
python tool/kanji/build_seed.py --validate-only
python tool/kanji/build_seed.py --validate-only --release
```

Lần đầu cần mạng để lấy archive KanjiVG pin commit. Snapshot KANJIDIC2 đã lưu tại `sources/kanjidic2.xml.gz`; cả hai nguồn đều được kiểm SHA-256 theo `sources.lock.json`. Xóa riêng cache tải về rồi chạy lại vẫn dùng đúng nguồn. Không tự chấp nhận checksum mới.

Đầu vào biên tập:

- `radicals.tsv`: tên/nghĩa/số nét/dạng bộ thủ.
- `meanings_vi.tsv`: 2.136 nghĩa tiếng Việt nháp, diễn giải từ nghĩa Anh của KANJIDIC2.
- `curated_vi.json`: ghi đè nghĩa/âm Hán Việt và `review_status`. Âm Hán Việt còn lại lấy từ KANJIDIC2; hai chữ thiếu được bổ sung dưới trạng thái nháp.

`validation_report.json` là kết quả kiểm tra máy, **không thay thế duyệt ngôn ngữ**. `review_samples.md` có mẫu phân tầng theo lớp và các trường hợp cấu tạo dễ nhầm. Hiện không có ký tự nào được ghi là con người đã duyệt. Chia danh mục thành từng lô, sửa nội dung trong đầu vào rồi chỉ đặt `review_status: "approved"` cho những ký tự thực sự đã duyệt; nên lưu thêm `reviewer`, `reviewed_at`, `review_note` trong từng bản ghi. Gate `--release` yêu cầu toàn bộ 2.136 ký tự có dữ liệu và trạng thái approved. Do đó **gate phát hành hiện cố ý không pass**.

Đầu ra tự sinh: migration `202609050003_seed_kanji_catalog.sql`, `assets/kanji/sources.json`, báo cáo, mẫu duyệt và `.cache/catalog.json` dùng cho corpus test. Không viết tay SQL seed. Chỉ chạy generator để thay migration này khi nó **chưa triển khai**. Sau khi đã triển khai, đổi đích generator thành migration có timestamp mới, duyệt diff và bảo toàn lịch sử migration; khi thay đổi thành phần phải xử lý cả những quan hệ cũ bị loại bỏ.

Giấy phép/nguồn chi tiết ở `assets/kanji/ATTRIBUTION.md`. Trước phát hành thương mại, người phụ trách cần xác nhận attribution, phân phối dữ liệu phái sinh và quy trình cập nhật nguồn đáp ứng điều khoản EDRDG/KanjiVG. Không coi việc generator pass là xác nhận pháp lý.

## Cache/offline

- SVG: memory LRU 64 chữ; SharedPreferences/browser storage tối đa khoảng 2 MiB hoặc 100 SVG, khóa gồm phiên bản và code point. Khởi động lại vẫn đọc được SVG còn trong cache. Có thể bị loại bỏ khi vượt hạn mức hoặc khi người dùng xóa dữ liệu trình duyệt.
- Metadata/component cache: khoảng 1 MiB/200 mục. Snapshot thống kê lưu riêng theo user ID; không dùng snapshot của tài khoản khác.
- Khi offline và còn phiên đăng nhập, màn hình mất mạng có nút “Xem Hán tự đã lưu”. Mở lại các chữ đã xem không cần gọi cloud; nội dung chưa từng lưu cần tải lần đầu khi online.
- Không lưu token trong cache tính năng. Lỗi quyền, auth hoặc schema không bị che bởi snapshot cũ. Cache không thay thế Supabase làm nguồn dữ liệu chính, không có hàng đợi ghi offline.

## Kiểm thử

```powershell
flutter analyze
flutter test
flutter test test/features/kanji --dart-define=KANJI_CORPUS=true
flutter test test/features/kanji/kanji_ui_test.dart --dart-define=KANJI_CAPTURE=true
flutter build web --release
```

Corpus test cần chạy generator trước. Capture là kiểm tra ảnh tùy chọn trên Windows, dùng Segoe UI tại `C:/Windows/Fonts/segoeui.ttf`, ghi PNG vào `build/kanji_qa/`; test thông thường không cần font hệ thống này. Bộ mới kiểm tra mapping/Unicode, không tự tính, đúp thao tác, lỗi, cache cách ly tài khoản, parser/toàn bộ SVG, fallback tĩnh, animation/giảm chuyển động, UI nhỏ/chữ lớn, điều hướng, dialog và hai điểm vào.

Database trên **Supabase local/staging test database**, không chạy trên production:

```powershell
supabase db reset
supabase test db
```

`supabase/tests/kanji_stats_test.sql` chứa 16 assertion pgTAP và dùng `fixtures/kanji_assertions.sql` để kiểm RPC/RLS dưới hai role người dùng. Fixtures rollback toàn bộ dữ liệu giả, kiểm chữ lặp, xóa từ, trường rỗng, chữ ngoài BMP, >1.000 kết quả và lỗi giữa transaction.

Fallback khi chưa có Supabase CLI/Postgres local:

```powershell
python tool/kanji/prepare_test_db.py
node tool/kanji/test_database.mjs
```

Harness PGlite pin 0.3.14 tạo Postgres WASM riêng trong bộ nhớ, giả lập `auth.uid()`/role, chạy toàn bộ migrations và **cùng assertions giao dịch**; không kết nối cloud. Nó không chạy extension pgTAP hay hệ thống Supabase Auth/PostgREST thật. Benchmark 1.000/10.000/50.000 dòng ghi `benchmark_report.json`; số đo này không phải độ trễ production và không chứng minh mục tiêu <50 ms. Cần benchmark lại trên staging qua RPC với hạ tầng/dữ liệu gần thực tế.

## Checklist trước phát hành

Kết quả tại lần bàn giao: `flutter analyze` không có lỗi; **147 tests pass** khi bật cả corpus 2.136 SVG và capture UI; assertions database PGlite pass; seed sinh lại có cùng checksum và release gate từ chối dữ liệu chưa duyệt đúng như thiết kế. Chạy thử `flutter test --platform chrome` dừng ở bước loading, đã hủy; không ghi nhận là pass kiểm thử trình duyệt.

- [ ] Con người duyệt dữ liệu tiếng Việt/âm Hán Việt theo lô, tên bộ/dạng/thành phần; chạy gate `--release`.
- [ ] Xác nhận điều khoản dữ liệu và attribution.
- [ ] Chạy pgTAP trên Supabase local, smoke test RLS/Auth/PostgREST và benchmark trên staging.
- [ ] Áp dụng migrations `202609050002` rồi `202609050003` vào môi trường đã chọn trước khi triển khai client.
- [ ] Kiểm thử trên thiết bị Android và iOS: cache sau đóng/mở app ở chế độ máy bay, Pause/Replay, giảm chuyển động, SVG lỗi và chữ ngoài BMP.
- [ ] Kiểm thử bản web đã triển khai cùng storage/CORS và offline sau tải lần đầu.

Giới hạn môi trường hiện tại: bản web có thể build; Android debug bị Java/Gradle báo `Unable to establish loopback connection` trên máy này (thử IPv4 vẫn lỗi); iOS chưa build/test được trên Windows. Không coi các nền tảng này đã nghiệm thu chỉ vì widget test pass.
