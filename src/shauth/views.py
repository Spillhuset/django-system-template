from django.shortcuts import redirect
from jwt import decode
from django.conf import settings
from django.contrib.auth.models import User, Group
from django.contrib.auth import login

def auth(request):
    token = request.GET.get("shauth")

    if token:
        try:
          decoded = decode(token, settings.SHAUTH_ENCRYPTION_KEY, algorithms=["HS256"])
          if decoded:
              users = User.objects.filter(username=decoded["id"])
              if users: user = users[0]
              else: user = User.objects.create_user(decoded["id"])
              user.first_name = decoded["name"]

              apply_groups(user, decoded["userFlags"])

              # Systems get admin
              if decoded["userFlags"] & 1 << 11:
                user.is_superuser = True
                user.is_staff = True

              user.save()
              login(request, user, backend="django.contrib.auth.backends.ModelBackend")
              return redirect("/")
        except Exception as e:
          print("exception:", e)
          pass

    return redirect("https://shauth.but-it-actually.works/?state=" + settings.SHAUTH_SYSTEM_NAME);

def apply_groups(user, flags):
  user.groups.clear()
  if flags & 1 << 0: user.groups.add(find_or_create_group("Crew"))
  if flags & 1 << 1: user.groups.add(find_or_create_group("Nøkkel"))
  if flags & 1 << 2: user.groups.add(find_or_create_group("Rådgiver"))
  if flags & 1 << 3: user.groups.add(find_or_create_group("Leder"))
  if flags & 1 << 4: user.groups.add(find_or_create_group("Event"))
  if flags & 1 << 5: user.groups.add(find_or_create_group("Event Leder"))
  if flags & 1 << 6: user.groups.add(find_or_create_group("PR"))
  if flags & 1 << 7: user.groups.add(find_or_create_group("PR Leder"))
  if flags & 1 << 8: user.groups.add(find_or_create_group("Streaming"))
  if flags & 1 << 9: user.groups.add(find_or_create_group("Streaming Leder"))
  if flags & 1 << 10: user.groups.add(find_or_create_group("HR"))
  if flags & 1 << 11: user.groups.add(find_or_create_group("Systemstøtte"))
  if flags & 1 << 12: user.groups.add(find_or_create_group("Styre"))
  if flags & 1 << 13: user.groups.add(find_or_create_group("Styre Leder"))

def find_or_create_group(name):
  groups = Group.objects.filter(name=name)
  if groups: return groups[0]
  group = Group.objects.create(name=name)
  group.save()
  return group
