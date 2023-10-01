from django.shortcuts import render, redirect
from django.conf import settings

def index(request):
    if not request.user.is_authenticated:
        if settings.SHAUTH_SYSTEM_NAME is None: return redirect("/accounts/login")
        else: return redirect("/auth")
    return render(request, "base.html")
