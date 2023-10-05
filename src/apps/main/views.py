from django.shortcuts import render, redirect
from django.conf import settings
from django.contrib.auth.decorators import login_required

from .models import *
from .forms import *

def index(request):
  if not request.user.is_authenticated:
    if settings.SHAUTH_SYSTEM_NAME is None: return redirect("/accounts/login")
    else: return redirect("/auth")
  return render(request, "main/index.html")
