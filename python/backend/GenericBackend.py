
import requests
from socketIO_client import SocketIO

class GenericBackend:

	def __init__(self):
		self.socket = SocketIO(self.serverUrl(), verify=False)

	def getRequest(self, rest):
	 	return "%s/rest/1.0/%s" % (self.serverUrl(), rest)

	def login(self, username, password):
		r = requests.post("%s/login" % self.serverUrl(), data={'name': username, 'password': password})
		if r.status_code == 200:
			self.cookies = r.cookies
			return True
		else:
			print "error", r.status_code
			return False

	def get(self, rest):
		r = requests.get(self.getRequest(rest), cookies=self.cookies)
		if r.status_code == 200:
			return r.json()
		else:
			print "error", r.status_code
			return None

	def post(self, rest, data):
		r = requests.post(self.getRequest(rest), data=data, cookies=self.cookies)
		if r.status_code == 200:
			return r.json()
		else:
			print "error", r.status_code
			return None
