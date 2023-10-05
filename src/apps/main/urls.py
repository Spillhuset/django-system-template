from . import views
from django.urls import include, path
from django.views.generic import TemplateView

urlpatterns = [
  path("", views.index, name="index"),
]
