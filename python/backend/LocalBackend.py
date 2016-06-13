
from backend import *

class LocalBackend(GenericBackend):

	 def serverUrl(self):
	 	return 'http://localhost:8081'
	 def username(self):
	 	return 'tracy'
	 def password(self):
	 	return 'password'
