-- 사용자가 자신의 계정만 삭제할 수 있습니다. 연결된 글과 프로필은 CASCADE로 삭제됩니다.
create function public.delete_my_account() returns void
language plpgsql security definer set search_path = '' as $$
declare current_user_id uuid;
begin
  current_user_id := auth.uid();
  if current_user_id is null then
    raise exception '로그인이 필요합니다';
  end if;
  delete from auth.users where id = current_user_id;
end;
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
