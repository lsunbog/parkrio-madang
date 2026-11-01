# 파크리오마당

주민이 운영하는 비공식 커뮤니티입니다. GitHub Pages 정적 화면과 Supabase Auth·Database·Storage를 사용합니다.

## 구성

- `index.html`, `style.css`, `app.js`: 반응형 화면과 회원·게시판 기능
- `config.js`: 공개 가능한 Supabase URL과 publishable key만 저장
- `supabase/schema.sql`, `supabase/account_deletion.sql`: 새 프로젝트에 적용한 데이터 구조와 접근 정책
- `assets/parkrio-illustration.png`: 기존 프로젝트 화면에서 분리한 일러스트

기존 사이트의 브라우저 저장 자료는 새 Supabase DB로 자동 이동하지 않습니다. 원본 HTML은 작업 폴더의 `기존화면-원본.html`에 보관되어 있습니다. 사진·안건 양식·역사 원자료는 아직 전달되지 않아 확정된 사실처럼 게시하지 않았습니다.

## 운영 설정

1. Supabase Auth의 URL Configuration에서 Site URL과 Redirect URLs에 실제 GitHub Pages 주소를 등록합니다.
2. Supabase Auth의 이메일 확인을 켜고 운영용 이메일 발송 서비스를 연결합니다.
3. 운영자 본인이 회원가입·이메일 인증을 마친 뒤 Supabase Auth 사용자 `raw_app_meta_data`에 `{"site_role":"admin"}`을 설정합니다. 일반 사용자가 편집 가능한 `user_metadata`는 권한에 사용하지 않습니다.
4. 회원 운영 규칙, 개인정보 보관·삭제 기준, 문의처를 확정한 뒤 공개합니다.
5. 가입·로그인·재설정 메일, 비회원/회원/관리자 접근 차단, 회원 탈퇴, 모바일 화면을 실제 계정으로 점검합니다.

`service_role` 또는 secret key를 웹 파일이나 GitHub에 넣지 마세요. 계정 삭제 RPC는 로그인한 본인의 ID만 삭제할 수 있도록 제한되어 있습니다.
