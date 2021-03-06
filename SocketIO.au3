#cs
	Copyright (c) 2017 TarreTarreTarre <tarre.islam@gmail.com>

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
#ce
#include-once
#include <Crypt.au3>
#AutoIt3Wrapper_Au3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w 7
Global Const $g__io_sVer = "2.0.0"
Global Enum $_IO_SERVER, $_IO_CLIENT
Global $g__io_DevDebug = False, _
		$g__io_isActive = Null, _
		$g__io_vCryptKey = Null, _
		$g__io_vCryptAlgId = Null, _
		$g__io_sOnEventPrefix = Null, _
		$g__iBiggestSocketI = 0, _
		$g__io_sockets[1] = [0], _
		$g__io_aBanlist[1] = [0], _
		$g__io_socket_rooms[1] = [0], _
		$g__io_aMiddlewares[1] = [0], _
		$g__io_whoami, _
		$g__io_max_dead_sockets_count = 0, _
		$g__io_events[1000] = [0], _
		$g__io_mySocket, _
		$g__io_dead_sockets_count = 0, _
		$g__io_conn_ip, _
		$g__io_conn_port, _
		$g__io_UsedProperties[1] = [0], _
		$g__io_AutoReconnect = Null, _
		$g__io_nPacketSize = Null, _
		$g__io_nMaxPacketSize = Null, _
		$g__io_nMaxConnections = Null, _
		$g__Io_socketPropertyDomain = Null



; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_RegisterMiddleware
; Description ...: Middlewares are ran before the event is fired which makes it a great tool for validation, data manipulation and debugging.
; Syntax ........: _Io_RegisterMiddleware($sEventName, $fCallback)
; Parameters ....: $sEventName          - a string value.
;                  $fCallback           - a floating point value.
; Return values .: True if middleware registrered with success.
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: Set $sEventName to * to trigger the middleware on every event. The $fCallback must be a valid function and the function MUST have these params (const $socket, ByRef $params, const $sEventName, ByRef $fCallbackName) and return true or false. False prevents the event from being fired.
; Related .......: _Io_unRegisterMiddleware, _Io_unRegisterEveryMiddleware
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_RegisterMiddleware($sEventName, $fCallback)

	If Not IsFunc($fCallback) Then Return SetError(1, 0, Null)

	If Not __Io_ValidEventName($sEventName) Then Return SetError(2, 0, Null)

	Local $aRet = [$sEventName, FuncName($fCallback), $fCallback]

	__Io_Push($g__io_aMiddlewares, $aRet)

	Return True ; $mwFuncCallback($socket, $r_params, $sEventName, $fCallbackName)

EndFunc   ;==>_Io_RegisterMiddleware

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_unRegisterMiddleware
; Description ...: Unregister a previously created middleware
; Syntax ........: _Io_unRegisterMiddleware($sEventName, $fCallback)
; Parameters ....: $sEventName          - a string value.
;                  $fCallback           - a floating point value.
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......: _Io_RegisterMiddleware, _Io_unRegisterEveryMiddleware
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_unRegisterMiddleware($sEventName, $fCallback)

	Local $success = False

	For $i = 1 To $g__io_aMiddlewares[0]
		Local $cur = $g__io_aMiddlewares[$i]

		Local $mwTargetEvent = $cur[0]
		Local $mwFuncName = $cur[1]

		If $sEventName == $mwTargetEvent And FuncName($fCallback) == $mwFuncName Then
			$g__io_aMiddlewares[$i] = Null
			$success = True
		EndIf
	Next

	Return $success

EndFunc   ;==>_Io_unRegisterMiddleware

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_unRegisterEveryMiddleware
; Description ...: Unregister every created middleware.
; Syntax ........: _Io_unRegisterEveryMiddleware()
; Parameters ....:
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......: _Io_unRegisterMiddleware, _Io_RegisterMiddleware
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_unRegisterEveryMiddleware()

	If $g__io_aMiddlewares[0] == 0 Then Return False

	For $i = 1 To $g__io_aMiddlewares[0]
		$g__io_aMiddlewares[$i] = Null
	Next

	Return True
EndFunc   ;==>_Io_unRegisterEveryMiddleware

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_setPropertyDomainPrefix
; Description ...: Server-side only. Sets the prefix for all props in _Io_socketSetProperty. Only use this if you are experiencing bugs with eval
; Syntax ........: _Io_setPropertyDomainPrefix($sDomain)
; Parameters ....: $sDomain             - a string value.
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: Only use this if you are experiencing bugs with eval
; Related .......: _Io_socketGetProperty, _Io_socketSetProperty
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_setPropertyDomainPrefix($sDomain)
	If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_setPropertyDomainPrefix: $g__Io_socketPropertyDomain = " & $sDomain & @LF)
	$g__Io_socketPropertyDomain = $sDomain
EndFunc   ;==>_Io_setPropertyDomainPrefix

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_whoAmI
; Description ...: Returns either `$_IO_SERVER` for server or `$_IO_CLIENT` for client
; Syntax ........: _Io_whoAmI([$verbose = false])
; Parameters ....: $verbose             - [optional] a variant value. Default is false.
; Return values .: Bool|String
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: This value is changed when invoking _Io_listen and _Io_Connect. If you set $verbose to `true`. This function retruns either "SERVER" or "CLIENT" instead of the constants
; Related .......: _Io_listen, _Io_Connect, _Io_IsServer, _Io_IsClient
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_whoAmI($verbose = False)
	Return Not $verbose ? $g__io_whoami : _Io_IsServer() ? 'SERVER' : 'CLIENT'
EndFunc   ;==>_Io_whoAmI

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_IsServer
; Description ...: Determines if _Io_whoAmI() == $_IO_SERVER
; Syntax ........: _Io_IsServer()
; Parameters ....:
; Return values .: Bool
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: This value is changed when invoking _Io_listen and _Io_Connect
; Related .......:  _Io_listen, _Io_Connect, _Io_whoAmI, _Io_IsClient
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_IsServer()
	Return $g__io_whoami == $_IO_SERVER
EndFunc   ;==>_Io_IsServer

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_IsClient
; Description ...: Determines if _Io_whoAmI() == $_IO_CLIENT
; Syntax ........: _Io_IsClient()
; Parameters ....:
; Return values .: Bool
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: This value is changed when invoking _Io_listen and _Io_Connect
; Related .......:   _Io_listen, _Io_Connect, _Io_IsServer, _Io_whoAmI
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_IsClient()
	Return $g__io_whoami == $_IO_CLIENT
EndFunc   ;==>_Io_IsClient

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_DevDebug
; Description ...: Enables debugging in console.
; Syntax ........: _Io_DevDebug($bState)
; Parameters ....: $bState              - a boolean value.
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_DevDebug($bState)
	$g__io_DevDebug = $bState
	ConsoleWrite("-" & @TAB & "_Io_DevDebug: @AutoItVersion = " & @AutoItVersion & @LF)
EndFunc   ;==>_Io_DevDebug

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_Listen
; Description ...:  Server-side only. Listens for incomming connections.
; Syntax ........: _Io_Listen($iPort[, $sAddress = @IPAddress1[, $iMaxPendingConnections = Default[,
;                  $iMaxDeadSocketsBeforeTidy = 1000[, $iMaxConnections = 100000]]]])
; Parameters ....: $iPort               - an integer value.
;                  $sAddress            - [optional] a string value. Default is @IPAddress1.
;                  $iMaxPendingConnections- [optional] an integer value. Default is Default.
;                  $iMaxDeadSocketsBeforeTidy- [optional] an integer value. Default is 1000.
;                  $iMaxConnections     - [optional] an integer value. Default is 100000.
; Return values .: integer. Null + @error if error
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: If `$iMaxDeadSocketsBeforeTidy` is set to `False`, you have to manually call `_Io_TidyUp` to get rid of dead sockets, otherwise the `iMaxConnections + 1` client that connects, will be instantly disconnected.
; Related .......: _Io_Connect
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_Listen($iPort, $sAddress = @IPAddress1, $iMaxPendingConnections = Default, $iMaxDeadSocketsBeforeTidy = 1000, $iMaxConnections = 100000)
	If Not __Io_Init() Then Return SetError(1, 0, Null)
	Local $socket = TCPListen($sAddress, $iPort, $iMaxPendingConnections)
	If @error Then Return SetError(2, @error, Null)
	$g__io_whoami = $_IO_SERVER
	$g__io_mySocket = $socket
	$g__io_max_dead_sockets_count = $iMaxDeadSocketsBeforeTidy
	$g__io_nMaxConnections = $iMaxConnections * 3 ; * 3 because all elementz
	$g__io_isActive = True
	;Global $g__io_events[1001] = [0]
	Global $g__io_sockets[($iMaxConnections * 3) + 1] = [0] ; *3 for all elements
	Global $g__io_socket_rooms[$iMaxConnections + 1] = [0]
	Global $g__io_aBanlist[(($iMaxConnections / 4) * 5) + 1] = [0] ; 25% of max connections * 5 etries +1 for sizeslot
	__Io_Ban_LoadToMemory()

	_Io_setPropertyDomainPrefix('default')

	If $g__io_DevDebug Then
		ConsoleWrite("-" & @TAB & "_Io_Listen: $g__io_sVer " & $g__io_sVer & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Listen: $sAddress " & $sAddress & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Listen: $iPort " & $iPort & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Listen: $g__io_whoami " & ($g__io_whoami == $_IO_SERVER ? 'Server' : 'Client') & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Listen: $g__io_mySocket " & $g__io_mySocket & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Listen: $g__io_max_dead_sockets_count " & $g__io_max_dead_sockets_count & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Listen: $g__io_nMaxConnections " & ($g__io_nMaxConnections / 3) & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Listen: $g__io_isActive " & $g__io_isActive & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Listen: $g__io_vCryptKey " & $g__io_vCryptKey & @LF)
	EndIf

	Return $socket
EndFunc   ;==>_Io_Listen

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_Connect
; Description ...: Attempts to connect to a Server.
; Syntax ........: _Io_Connect($sAddress, $iPort[, $bAutoReconnect = True])
; Parameters ....: $sAddress            - a string value.
;                  $iPort               - an integer value.
;                  $bAutoReconnect      - [optional] a boolean value. Default is True.
; Return values .: integer. Null + @error if unable to connect.
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: if `$bAutoReconnect` is set to `False`. You must use `_Io_Connect` or `_Io_Reconnect` to establish a new connection.
; Related .......: _Io_Reconnect
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_Connect($sAddress, $iPort, $bAutoReconnect = True)
	If Not __Io_Init() Then Return SetError(1, 0, Null)
	Local $socket = TCPConnect($sAddress, $iPort)
	If @error Then Return SetError(2, @error, Null)
	;Global $g__io_events[1001] = [0]
	$g__io_whoami = $_IO_CLIENT
	$g__io_mySocket = $socket
	$g__io_conn_ip = $sAddress
	$g__io_conn_port = $iPort
	$g__io_AutoReconnect = $bAutoReconnect
	$g__io_isActive = True

	If $g__io_DevDebug Then
		ConsoleWrite("-" & @TAB & "_Io_Connect: $g__io_sVer " & $g__io_sVer & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Connect: $sAddress " & $sAddress & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Connect: $iPort " & $iPort & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Connect: $g__io_whoami " & ($g__io_whoami == $_IO_SERVER ? 'Server' : 'Client') & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Connect: $g__io_mySocket " & $g__io_mySocket & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Connect: $g__io_conn_ip " & $g__io_conn_ip & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Connect: $g__io_conn_port " & $g__io_conn_port & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Connect: $g__io_AutoReconnect " & String($g__io_AutoReconnect) & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Connect: $g__io_isActive " & $g__io_isActive & @LF)
		ConsoleWrite("-" & @TAB & "_Io_Connect: $g__io_vCryptKey " & $g__io_vCryptKey & @LF)
	EndIf

	Return $socket
EndFunc   ;==>_Io_Connect

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_EnableEncryption
; Description ...: Encrypts data before transmission using AutoIt's Crypt.au3
; Syntax ........: _Io_EnableEncryption($sFileOrKey)
; Parameters ....: $sFileOrKey          - a string value.
; Return values .: `True` if successfully configured. Null + @error if wrongfully configured. Use @Extended to see which type of internal error is thrown.
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: The encryption has to be configured equally on both sides for it to work.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_EnableEncryption($sFileOrKey, $CryptAlgId = $CALG_AES_256)
	Local Const $test_string = "2 legit 2 quit"
	If FileExists($sFileOrKey) Then
		$sFileOrKey = FileRead($sFileOrKey)
		If @error Then
			Return SetError(1, @error, Null)
		EndIf
	EndIf

	; Attempt to init Cryp
	_Crypt_Startup()
	If @error Then
		Return SetError(2, @error, Null)
	EndIf

	; Validate settings
	Local $test_encrypt_data = _Crypt_EncryptData($test_string, $sFileOrKey, $CryptAlgId)

	If @error Then
		Return SetError(3, @error, Null)
	EndIf

	Local $test_decrypt_data = _Crypt_DecryptData($test_encrypt_data, $sFileOrKey, $CryptAlgId)

	If @error Then
		Return SetError(4, @error, Null)
	EndIf

	; Test encryption
	If BinaryToString($test_decrypt_data) == $test_string Then
		$g__io_vCryptKey = $sFileOrKey
		$g__io_vCryptAlgId = $CryptAlgId
		Return True
	EndIf

	Return SetError(5, -1, Null)
EndFunc   ;==>_Io_EnableEncryption

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_setRecvPackageSize
; Description ...: Sets the maxlen for [TCPRecv](https://www.autoitscript.com/autoit3/docs/functions/TCPRecv.htm)
; Syntax ........: _Io_setRecvPackageSize([$iPackageSize = 4096])
; Parameters ....: $iPackageSize        - [optional] a general number value. Default is 4096
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_setRecvPackageSize($iPackageSize = 4096)
	$g__io_nPacketSize = $iPackageSize
EndFunc   ;==>_Io_setRecvPackageSize

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_setMaxRecvPackageSize
; Description ...: Sets the threshold for the `flood` event
; Syntax ........: _Io_setMaxRecvPackageSize([$iMaxPackageSize = $g__io_nPacketSize])
; Parameters ....: $iMaxPackageSize     - [optional] a general number value. Default is $g__io_nPacketSize.
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_setMaxRecvPackageSize($iMaxPackageSize = $g__io_nPacketSize)
	$g__io_nMaxPacketSize = $iMaxPackageSize
EndFunc   ;==>_Io_setMaxRecvPackageSize

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_Reconnect
; Description ...: Attempts to reconnect to the server
; Syntax ........: _Io_Reconnect(ByRef $socket)
; Parameters ....: $socket              - [in/out] a socket.
; Return values .: a new socket ID
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: Client-side only. This function invokes `_Io_TransferSocket` which will cause the param $socket passed, to be replaced with the new socket.
; Related .......: _Io_Connect, _Io_TransferSocket
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_Reconnect(ByRef $socket)
	; Create new socket
	Local $new_socket = _Io_Connect($g__io_conn_ip, $g__io_conn_port)
	; Transfer socket and events
	_Io_TransferSocket($socket, $new_socket)
	Return $socket
EndFunc   ;==>_Io_Reconnect

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_Subscribe
; Description ...: Server-side only. Subscribes a socket to a room.
; Syntax ........: _Io_Subscribe(Const $socket, $sRoomName)
; Parameters ....: $socket              - [in/out] a string value.
;                  $sRoomName           - a string value.
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......: _Io_BroadcastToRoom, _Io_Unsubscribe
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_Subscribe(Const $socket, $sRoomName)
	__Io_Push2x($g__io_socket_rooms, $socket, $sRoomName)
EndFunc   ;==>_Io_Subscribe

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_Unsubscribe
; Description ...: Server-side only. Unsubscribes a socket from a room.
; Syntax ........: _Io_Unsubscribe(Const $socket, $sRoomName)
; Parameters ....: $socket              - [in/out] a string value.
;                  $sRoomName           - a string value.
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: If $sRoomName is null, every subscription will expire for the given socket.
; Related .......: _Io_Subscribe
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_Unsubscribe(Const $socket, $sDesiredRoomName = Null)

	For $i = 1 To $g__io_socket_rooms[0] Step +2
		If $g__io_socket_rooms[$i] == $socket And ($g__io_socket_rooms[$i + 1] == $sDesiredRoomName Or $sDesiredRoomName == Null) Then
			$g__io_socket_rooms[$i] = Null
			$g__io_socket_rooms[$i + 1] = Null
		EndIf
	Next

EndFunc   ;==>_Io_Unsubscribe

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_Disconnect
; Description ...: Manually disconnect as Client or server / Disconnects a client
; Syntax ........: _Io_Disconnect([$socket = Null])
; Parameters ....: $socket              - [optional] a string value. Default is Null.
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: This function will purge any previously set `_Io_LoopFacade` and cause `_Io_Loop` to return false. If the `$socket` parameter is set when running as a server, the id of that socket will be disconnected.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_Disconnect($socket = Default)
	If $g__io_whoami == $_IO_SERVER And @NumParams == 1 Then
		Return TCPCloseSocket($socket)
	EndIf
	$g__io_isActive = False
	AdlibUnRegister("_Io_LoopFacade")
	__Io_Shutdown()
	Return True
EndFunc   ;==>_Io_Disconnect

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_LoopFacade
; Description ...: A substitute for the `_Io_Loop`.
; Syntax ........: _Io_LoopFacade()
; Parameters ....:
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: Should only be used with AdlibRegister. If `_Io_Disconnect` is invoked, this facade will also be un-registered. This function will not work properly if more than 1 `_Io_Connect` or `_Io_Listen` exists in the same script.
; Related .......: _Io_Loop
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_LoopFacade()
	_Io_Loop($g__io_mySocket)
EndFunc   ;==>_Io_LoopFacade

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_Loop
; Description ...: The event handler for this UDF.
; Syntax ........: _Io_Loop(Byref $socket)
; Parameters ....: $socket              - [in/out] a string value.
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: Should only be used as the main While loop. The function will return false if the function `_Io_Disconnect` is invoked
; Related .......: _Io_LoopFacade
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_Loop(ByRef $socket, $whoAmI = $g__io_whoami)
	Local $package, $aParams = Null

	Switch $whoAmI
		Case $_IO_SERVER

			; -------------
			;	Check for incomming connections
			; -------------

			Local $connectedSocket = TCPAccept($socket)

			If $connectedSocket <> -1 Then

				; Check if we have room for another one (Even dead sockets takes spaces, so therefore were not including $g__io_dead_sockets_count)
				If $g__io_sockets[0] + 1 <= $g__io_nMaxConnections Then ; $g__io_nMaxConnections has *3 so it will not be bothered by the dim size
					; Create an socket with more info, but in an separate array
					Local $aExtendedSocket = __Io_createExtendedSocket($connectedSocket)

					; Check if banned
					Local $isBanned = _Io_IsBanned($aExtendedSocket[1])

					If $isBanned > 0 Then

						;get banned-data
						Local $aBannedInfo = _Io_getBanlist($isBanned)

						; Emit ban notification
						_Io_Emit($connectedSocket, "banned", $aBannedInfo[1], $aBannedInfo[2], $aBannedInfo[3], $aBannedInfo[4])

						; Close socket
						_Io_Disconnect($connectedSocket)

						; Return
						Return $g__io_isActive

					EndIf

					; This is done to exit any $g__io_socket's loop and break when we know we are not going to find anything more
					;If $connectedSocket > $g__iBiggestSocketI Then $g__iBiggestSocketI = $connectedSocket + 1
					$g__iBiggestSocketI += 3

					; Save socket
					__Io_Push3x($g__io_sockets, $aExtendedSocket[0], $aExtendedSocket[1], $aExtendedSocket[2])

					; Fire connection event
					__Io_FireEvent($connectedSocket, $aParams, "connection", $socket)
				Else
					; Close socket because were full!
					_Io_Disconnect($connectedSocket)
				EndIf
			EndIf

			; -------------
			;	Check client alive-status and see if any data was transmitted to the server
			; -------------

			Local $aDeadSockets[1] = [0]

			For $i = 1 To $g__io_sockets[0] Step +3
				Local $client_socket = $g__io_sockets[$i]

				; Ignore dead sockets
				If Not $client_socket > 0 Then ContinueLoop

				$package = __Io_RecvPackage($client_socket)

				Switch @error
					Case 1 ; Dead client
						; Add socket ID to array of dead sockets
						__Io_Push($aDeadSockets, $i)

						; Incr dead count
						$g__io_dead_sockets_count += 1

						ContinueLoop
					Case 2 ; Client flooding (Exceeding $g__io_nMaxPacketSize)
						__Io_FireEvent($client_socket, $aParams, "flood", $socket)
				EndSwitch

				; Collect all Processed data, so we can invoke them all at once instead of one by one
				If $package Then
					__Io_handlePackage($client_socket, $package, $socket)
				EndIf

				; Check if we can abort this loop
				If $i >= $g__iBiggestSocketI Then ExitLoop
			Next

			; -------------
			;	Handle all dead sockets
			; -------------

			For $i = 1 To $aDeadSockets[0]
				Local $aDeadSocket_index = $aDeadSockets[$i]
				Local $deadSocket = $g__io_sockets[$aDeadSocket_index]

				; Unsubscribe socket from everything
				_Io_Unsubscribe($deadSocket)

				; Fire event
				__Io_FireEvent($deadSocket, $aParams, "disconnect", $socket)

				; Mark socket as dead.
				$g__io_sockets[$aDeadSocket_index] = Null

				; Null out every possible set property on the deadsocket (Exactly like assign but without checks (for speed)
				For $j = 1 To $g__io_UsedProperties[0]
					Local $sProp = $g__io_UsedProperties[$j]
					Local $fqdn = $g__Io_socketPropertyDomain & "_" & $socket & $sProp
					Assign($fqdn, Null, 2)
				Next

			Next

			; -------------
			;	Determine if we need to tidy up (Remove all dead sockets)
			; -------------
			If $g__io_max_dead_sockets_count > 0 And $g__io_dead_sockets_count >= $g__io_max_dead_sockets_count Then
				_Io_TidyUp()
			EndIf

		Case $_IO_CLIENT
			; -------------
			;	Recv data from server
			; -------------

			$package = __Io_RecvPackage($socket)

			; -------------
			;	Check server alive-status
			; -------------

			Switch @error
				Case 1 ; Disconnected from server (Not by user)
					__Io_FireEvent($socket, $aParams, "disconnect", $socket) ; $socket two times is correct.
					; Reconnect if we need to
					If $g__io_AutoReconnect Then
						_Io_Reconnect($socket)
					EndIf
				Case 2 ; Flooded by server
					__Io_FireEvent($socket, $aParams, "flood", $socket) ; $socket two times is correct.
			EndSwitch


			; -------------
			;	Parse incomming data
			; -------------

			If $package Then
				__Io_handlePackage($socket, $package, $socket) ; $socket two times is correct.
			EndIf

	EndSwitch

	Return $g__io_isActive
EndFunc   ;==>_Io_Loop

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_setOnPrefix
; Description ...: Set the default prefix for `_Io_On` if not passing callback.
; Syntax ........: _Io_setOnPrefix(Const $sPrefix)
; Parameters ....: $sPrefix             - [const] a string value.
; Return values .: @error if invalid prefix
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: only function-friendly names are allowed
; Related .......: _Io_On
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_setOnPrefix(Const $sPrefix = '_On_')
	If Not StringRegExp($sPrefix, '(?i)[a-z_]+[a-z_0-9]*') Then
		If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_setOnPrefix: failed to set prefix ($sPrefix) to '" & $sPrefix & "'" & @LF)
		Return SetError(1)
	EndIf

	$g__io_sOnEventPrefix = $sPrefix

	If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_setOnPrefix: successfully set ($sPrefix) to '" & $sPrefix & "'" & @LF)
EndFunc   ;==>_Io_setOnPrefix

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_On
; Description ...: Binds an event
; Syntax ........: _Io_On(Const $sEventName[, $fCallback = Null[, $socket = $g__io_mySocket]])
; Parameters ....: $sEventName          - [Const] a string value.
;                  $fCallback           - [optional] a floating point value. Default is Null.
;                  $socket              - [optional] a string value. Default is $g__io_mySocket.
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: If $fCallback is set to null, the function will assume the prefix "_On_" is applied. Eg (_Io_On('test') will look for "Func _On_Test(...)" etc
; Related .......: _Io_setOnPrefix
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_On(Const $sEventName, Const $fCallback = Null, $socket = $g__io_mySocket)
	Local $fCallbackName = IsFunc($fCallback) ? FuncName($fCallback) : $fCallback

	If $fCallback == Null And Not StringRegExp($sEventName, '(?i)^[a-z_0-9]*$') Then
		If $g__io_DevDebug Then
			ConsoleWrite("-" & @TAB & StringFormat('_Io_On: Failed to bind event "%s". Invalid eventname for autoCallback.', $sEventName) & @LF)
		EndIf
		Return SetError(1)
	EndIf

	If Not $fCallbackName Then
		$fCallbackName = $g__io_sOnEventPrefix & $sEventName
	EndIf


	If $g__io_DevDebug Then
		ConsoleWrite("-" & @TAB & StringFormat('_Io_On: Bound new event: %s => %s', $sEventName, $fCallbackName) & @LF)
	EndIf

	__Io_Push3x($g__io_events, $sEventName, $fCallbackName, $socket)
EndFunc   ;==>_Io_On

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_Emit
; Description ...: Emit an event to a given $socket
; Syntax ........: _Io_Emit(Const $socket, $sEventName[, $p1 = Default[, $p2 = Default[, $p3 = Default[, $p4 = Default[,
;                  $p5 = Default[, $p6 = Default[, $p7 = Default[, $p8 = Default[, $p9 = Default[, $p10 = Default]]]]]]]]]])
; Parameters ....: $socket              - [in/out] a string value.
;                  $sEventName          - a string value.
;                  $p1                  - [optional] a pointer value. Default is Default.
;                  $p2                  - [optional] a pointer value. Default is Default.
;                  $p3                  - [optional] a pointer value. Default is Default.
;                  $p4                  - [optional] a pointer value. Default is Default.
;                  $p5                  - [optional] a pointer value. Default is Default.
;                  $p6                  - [optional] a pointer value. Default is Default.
;                  $p7                  - [optional] a pointer value. Default is Default.
;                  $p8                  - [optional] a pointer value. Default is Default.
;                  $p9                  - [optional] a pointer value. Default is Default.
;                  $p10                 - [optional] a pointer value. Default is Default.
; Return values .: Integer. Bytes sent
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: To pass more than 16 parameters, a special array can be passed in lieu of individual parameters. This array must have its first element set to "CallArgArray" and elements 1 - n will be passed as separate arguments to the function. If using this special array, no other arguments can be passed
; Related .......: _Io_Broadcast, _Io_BroadcastToAll, _Io_BroadcastToRoom
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_Emit(Const $socket, $sEventName, $p1 = Default, $p2 = Default, $p3 = Default, $p4 = Default, $p5 = Default, $p6 = Default, $p7 = Default, $p8 = Default, $p9 = Default, $p10 = Default, $p11 = Default, $p12 = Default, $p13 = Default, $p14 = Default, $p15 = Default, $p16 = Default)

	; No goof names allowed
	If Not __Io_ValidEventName($sEventName) Then Return SetError(1, 0, Null)

	; What to send
	Local $aParams = [$p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15, $p16]

	; Determine if a CallArgArray call is valid
	If @NumParams == 3 And IsArray($p1) And $p1[0] == 'CallArgArray' Then
		$aParams = $p1
	EndIf

	; Prepare package
	Local $package = __Io_createPackage($sEventName, $aParams, @NumParams)

	; attempt to send request
	Return __Io_TransportPackage($socket, $package)

EndFunc   ;==>_Io_Emit

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_Broadcast
; Description ...: Server-side only. Emit an event every connected socket but not the passed $socket
; Syntax ........: _Io_Broadcast(Const $socket, $sEventName[, $p1 = Default[, $p2 = Default[, $p3 = Default[, $p4 = Default[,
;                  $p5 = Default[, $p6 = Default[, $p7 = Default[, $p8 = Default[, $p9 = Default[, $p10 = Default]]]]]]]]]])
; Parameters ....: $socket              - [in/out] a string value.
;                  $sEventName          - a string value.
;                  $p1                  - [optional] a pointer value. Default is Default.
;                  $p2                  - [optional] a pointer value. Default is Default.
;                  $p3                  - [optional] a pointer value. Default is Default.
;                  $p4                  - [optional] a pointer value. Default is Default.
;                  $p5                  - [optional] a pointer value. Default is Default.
;                  $p6                  - [optional] a pointer value. Default is Default.
;                  $p7                  - [optional] a pointer value. Default is Default.
;                  $p8                  - [optional] a pointer value. Default is Default.
;                  $p9                  - [optional] a pointer value. Default is Default.
;                  $p10                 - [optional] a pointer value. Default is Default.
; Return values .: Integer. Bytes sent
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: To pass more than 16 parameters, a special array can be passed in lieu of individual parameters. This array must have its first element set to "CallArgArray" and elements 1 - n will be passed as separate arguments to the function. If using this special array, no other arguments can be passed
; Related .......: _Io_Emit, _Io_BroadcastToAll, _Io_BroadcastToRoom
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_Broadcast(Const $socket, $sEventName, $p1 = Default, $p2 = Default, $p3 = Default, $p4 = Default, $p5 = Default, $p6 = Default, $p7 = Default, $p8 = Default, $p9 = Default, $p10 = Default, $p11 = Default, $p12 = Default, $p13 = Default, $p14 = Default, $p15 = Default, $p16 = Default)

	; No goof names allowed
	If Not __Io_ValidEventName($sEventName) Then Return SetError(1, 0, Null)

	; What to send
	Local $aParams = [$p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15, $p16]

	; Determine if a CallArgArray call is valid
	If @NumParams == 3 And IsArray($p1) And $p1[0] == 'CallArgArray' Then
		$aParams = $p1
	EndIf

	; Prepare package
	Local $package = __Io_createPackage($sEventName, $aParams, @NumParams)
	Local $bytesSent = 0

	For $i = 1 To $g__io_sockets[0] Step +3
		Local $client_socket = $g__io_sockets[$i]

		; Ignore dead sockets and "self"
		If Not $client_socket > 0 Or $socket == $client_socket Then ContinueLoop

		; Send da package
		$bytesSent += __Io_TransportPackage($client_socket, $package)

		; Check if we can abort this loop
		If $i >= $g__iBiggestSocketI Then ExitLoop

	Next

	Return $bytesSent

EndFunc   ;==>_Io_Broadcast

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_BroadcastToAll
; Description ...: Server-side only. Emit an event every connected socket including the passed $socket
; Syntax ........: _Io_BroadcastToAll(Const $socket, $sEventName[, $p1 = Default[, $p2 = Default[, $p3 = Default[, $p4 = Default[,
;                  $p5 = Default[, $p6 = Default[, $p7 = Default[, $p8 = Default[, $p9 = Default[, $p10 = Default]]]]]]]]]])
; Parameters ....: $socket              - [in/out] a string value.
;                  $sEventName          - a string value.
;                  $p1                  - [optional] a pointer value. Default is Default.
;                  $p2                  - [optional] a pointer value. Default is Default.
;                  $p3                  - [optional] a pointer value. Default is Default.
;                  $p4                  - [optional] a pointer value. Default is Default.
;                  $p5                  - [optional] a pointer value. Default is Default.
;                  $p6                  - [optional] a pointer value. Default is Default.
;                  $p7                  - [optional] a pointer value. Default is Default.
;                  $p8                  - [optional] a pointer value. Default is Default.
;                  $p9                  - [optional] a pointer value. Default is Default.
;                  $p10                 - [optional] a pointer value. Default is Default.
; Return values .: Integer. Bytes sent
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: To pass more than 16 parameters, a special array can be passed in lieu of individual parameters. This array must have its first element set to "CallArgArray" and elements 1 - n will be passed as separate arguments to the function. If using this special array, no other arguments can be passed
; Related .......: _Io_Emit, _Io_Broadcast, _Io_BroadcastToRoom
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_BroadcastToAll(Const $socket, $sEventName, $p1 = Default, $p2 = Default, $p3 = Default, $p4 = Default, $p5 = Default, $p6 = Default, $p7 = Default, $p8 = Default, $p9 = Default, $p10 = Default, $p11 = Default, $p12 = Default, $p13 = Default, $p14 = Default, $p15 = Default, $p16 = Default)
	#forceref $socket
	; No goof names allowed
	If Not __Io_ValidEventName($sEventName) Then Return SetError(1, 0, Null)

	; What to send
	Local $aParams = [$p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15, $p16]

	; Determine if a CallArgArray call is valid
	If @NumParams == 3 And IsArray($p1) And $p1[0] == 'CallArgArray' Then
		$aParams = $p1
	EndIf

	; Prepare package
	Local $package = __Io_createPackage($sEventName, $aParams, @NumParams)
	Local $bytesSent = 0

	For $i = 1 To $g__io_sockets[0] Step +3
		Local $client_socket = $g__io_sockets[$i]

		; Ignore dead sockets only
		If Not $client_socket > 0 Then ContinueLoop

		; Send da package
		$bytesSent += __Io_TransportPackage($client_socket, $package)

		; Check if we can abort this loop
		If $i >= $g__iBiggestSocketI Then ExitLoop

	Next

	Return $bytesSent

EndFunc   ;==>_Io_BroadcastToAll

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_BroadcastToRoom
; Description ...: Server-side only. Emit an event to every socket subscribed to a given room
; Syntax ........: _Io_BroadcastToRoom(Const $socket, $sDesiredRoomName, $sEventName[, $p1 = Default[, $p2 = Default[, $p3 = Default[,
;                  $p4 = Default[, $p5 = Default[, $p6 = Default[, $p7 = Default[, $p8 = Default[, $p9 = Default[,
;                  $p10 = Default[, $p11 = Default[, $p12 = Default[, $p13 = Default[, $p14 = Default[, $p15 = Default[,
;                  $p16 = Default]]]]]]]]]]]]]]]])
; Parameters ....: $socket              - [in/out] a string value.
;                  $sDesiredRoomName    - a string value.
;                  $sEventName          - a string value.
;                  $p1                  - [optional] a pointer value. Default is Default.
;                  $p16                 - [optional] a pointer value. Default is Default.
; Return values .: Integer. Bytes sent
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: To pass more than 16 parameters, a special array can be passed in lieu of individual parameters. This array must have its first element set to "CallArgArray" and elements 1 - n will be passed as separate arguments to the function. If using this special array, no other arguments can be passed
; Related .......: _Io_Emit, _Io_Broadcast, _Io_BroadcastToAll, _Io_Subscribe
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_BroadcastToRoom(Const $socket, $sDesiredRoomName, $sEventName, $p1 = Default, $p2 = Default, $p3 = Default, $p4 = Default, $p5 = Default, $p6 = Default, $p7 = Default, $p8 = Default, $p9 = Default, $p10 = Default, $p11 = Default, $p12 = Default, $p13 = Default, $p14 = Default, $p15 = Default, $p16 = Default)
	#forceref $socket
	; No goof names allowed
	If Not __Io_ValidEventName($sEventName) Then Return SetError(1, 0, Null)

	; What to send
	Local $aParams = [$p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15, $p16]

	; Determine if a CallArgArray call is valid
	If @NumParams == 4 And IsArray($p1) And $p1[0] == 'CallArgArray' Then
		$aParams = $p1
	EndIf

	; Prepare package
	Local $package = __Io_createPackage($sEventName, $aParams, @NumParams - 1) ; - 1 since we have more params
	Local $bytesSent = 0

	For $i = 1 To $g__io_socket_rooms[0] Step +2
		Local $client_socket = $g__io_socket_rooms[$i]

		; Ignore dead sockets
		If Not $client_socket > 0 Then ContinueLoop

		Local $sRoomName = $g__io_socket_rooms[$i + 1]

		; Check if this is the room we want to send to
		If $sDesiredRoomName == $sRoomName Then
			$bytesSent += __Io_TransportPackage($client_socket, $package)
		EndIf

	Next

	Return $bytesSent

EndFunc   ;==>_Io_BroadcastToRoom

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_socketGetProperty
; Description ...:  Server-side only. Retrieves information about the socket.
; Syntax ........: _Io_socketGetProperty(Const $socket[, $sProp = Default[, $default = null]])
; Parameters ....: $socket              - [const] a string value.
;                  $sProp               - [optional] a string value. Default is Default.
;                  $default             - [optional] a binary variant value. Default is null.
; Return values .: Mixed
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: If $sProp is set to `Default` then an array containing two elements will be returned.
; Related .......: _Io_socketSetProperty, _Io_getFirstByProperty, _Io_getAllByProperty
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_socketGetProperty(Const $socket, $sProp = Default, $default = Null)

	; Get property from socket
	For $i = 1 To $g__io_sockets[0] Step +3

		If Not $g__io_sockets[$i] > 0 Then ContinueLoop

		If $g__io_sockets[$i] == $socket Then

			; Return all
			If $sProp == Default Then
				Local $aExtendedSocket = [$g__io_sockets[$i], $g__io_sockets[$i + 1], $g__io_sockets[$i + 2]]
				Return $aExtendedSocket
			EndIf

			; Return specific
			Switch $sProp
				Case "ip"
					Return $g__io_sockets[$i + 1]
				Case "date"
					Return $g__io_sockets[$i + 2]
				Case "socket" ; Redundant but required for code consistency
					Return $socket
				Case Else

					; If we have a custom prop. This is what it should be called
					Local $fqdn = $g__Io_socketPropertyDomain & "_" & $socket & $sProp

					If Not IsDeclared($fqdn) Then Return $default

					Return Eval($fqdn)

			EndSwitch

		EndIf

		; Check if we can abort this loop
		If $i >= $g__iBiggestSocketI Then ExitLoop

	Next

	Return SetError(1, 0, Null)
EndFunc   ;==>_Io_socketGetProperty

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_getFirstByProperty
; Description ...: Searches through every alive socket to find and return the first result of the desired properties.
; Syntax ........: _Io_getFirstByProperty($sPropToSearchFor, $valueToSearchFor, $propsToReturn[, $default = Null])
; Parameters ....: $sPropToSearchFor    - a string value.
;                  $valueToSearchFor    - a variant value.
;                  $propsToReturn        - a pointer value.
;                  $default             - [optional] a binary variant value. Default is Null.
; Return values .: Mixed
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: You can retrieve multiple properties by using commas. If nothing was found @error will be set and the $default value will be used.
; Related .......:  _Io_socketGetProperty, _Io_socketSetProperty, _Io_getAllByProperty
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_getFirstByProperty($sPropToSearchFor, $valueToSearchFor, $propsToReturn, $default = Null)
	Return __Io_makeSocketCollection($sPropToSearchFor, $valueToSearchFor, $propsToReturn, $default, False)
EndFunc   ;==>_Io_getFirstByProperty

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_getAllByProperty
; Description ...: Searches through every alive socket to find and return an array of results with the desired properties.
; Syntax ........: _Io_getAllByProperty($sPropToSearchFor, $valueToSearchFor, $propsToReturn)
; Parameters ....: $sPropToSearchFor    - a string value.
;                  $valueToSearchFor    - a variant value.
;                  $propsToReturn        - a pointer value.
; Return values .: Mixed
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:  You can retrieve multiple properties by using commas. If nothing was found an empty array will be returned. no @error
; Related .......:  _Io_socketGetProperty, _Io_socketSetProperty, _Io_getFirstByProperty
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_getAllByProperty($sPropToSearchFor, $valueToSearchFor, $propsToReturn)
	Return __Io_makeSocketCollection($sPropToSearchFor, $valueToSearchFor, $propsToReturn, Default, True)
EndFunc   ;==>_Io_getAllByProperty

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_socketSetProperty
; Description ...: Server-side only. Bind a custom property to a socket, which can be used later on
; Syntax ........: _Io_socketSetProperty(Const $socket, $sProp, $value)
; Parameters ....: $socket              - [const] a string value.
;                  $sProp               - a string value.
;                  $value               - a variant value.
; Return values .: True if successfull, @error if error.
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: the props `socket`, `ip` and `date` is reserved. @Error 1 = reserved prop name used. @Error 2 = invalid property name. Only a-zA-Z 0-9 and _ is allowed.
; Related .......: _Io_socketGetProperty, _Io_getFirstByProperty, _Io_getAllByProperty
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_socketSetProperty(Const $socket, $sProp, $value)

	If StringRegExp($sProp, "^(ip|date|socket)$") Then Return SetError(1, 0, Null)
	If Not StringRegExp($sProp, "(?i)^[a-z0-9_]+$") Then Return SetError(2, 0, Null)

	Local $fqdn = $g__Io_socketPropertyDomain & "_" & $socket & $sProp

	; Save prop so we can use it to tidy up dead sockets later
	__Io_Push($g__io_UsedProperties, $sProp)

	If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_socketSetProperty: Assigning an " & VarGetType($value) & " to " & $fqdn & @LF)

	Return Assign($fqdn, $value, 2) == 1

EndFunc   ;==>_Io_socketSetProperty

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_getVer
; Description ...: Returns the version of the UDF
; Syntax ........: _Io_getVer()
; Parameters ....:
; Return values .: SEMVER string (X.Y.Z)
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: See more on semver @ http://semver.org/
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_getVer()
	Return $g__io_sVer
EndFunc   ;==>_Io_getVer

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_getSocketsCount
; Description ...:  Server-side only. Returns the number of all sockets regardless of state.
; Syntax ........: _Io_getSocketsCount()
; Parameters ....:
; Return values .: integer
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: Includes disconnected sockets.
; Related .......: _Io_getDeadSocketCount, _Io_getActiveSocketCount, _Io_getSockets
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_getSocketsCount()
	Return Int($g__io_sockets[0] / 3)
EndFunc   ;==>_Io_getSocketsCount

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_getDeadSocketCount
; Description ...:  Server-side only. Returns the number of all dead sockets.
; Syntax ........: _Io_getDeadSocketCount()
; Parameters ....:
; Return values .: integer
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......: _Io_getSocketsCount, _Io_getActiveSocketCount, _Io_getSockets
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_getDeadSocketCount()
	Return $g__io_dead_sockets_count
EndFunc   ;==>_Io_getDeadSocketCount

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_getActiveSocketCount
; Description ...: Server-side only. Returns the number of all active sockets.
; Syntax ........: _Io_getActiveSocketCount()
; Parameters ....:
; Return values .: integer
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......: _Io_getSocketsCount, _Io_getDeadSocketCount, _Io_getSockets
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_getActiveSocketCount()
	Return _Io_getSocketsCount() - _Io_getDeadSocketCount()
EndFunc   ;==>_Io_getActiveSocketCount

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_getSockets
; Description ...: Returns all stored sockets, [$i + 0] = socket, [$i + 1] = ip, [$i + 2] = Date joined (YYYY-MM-DD HH:MM:SS)
; Syntax ........: _Io_getSockets([$bForceUpdate = False[, $socket = $g__io_mySocket[, $whoAmI = $g__io_whoami]]])
; Parameters ....: $bForceUpdate        - [optional] a boolean value. Default is False.
;                  $socket              - [optional] a string value. Default is $g__io_mySocket.
;                  $whoAmI              - [optional] an unknown value. Default is $g__io_whoami.
; Return values .: Array
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: Ubound wont work propery with this array, so use The `$aArr[1]` element to retrive the size. `For $i = 1 to $aArr[1] step +3 ......`. the socket is (Keyowrd) "Null" if the socket is dead.
; Related .......: _Io_getSocketsCount, _Io_getDeadSocketCount, _Io_getActiveSocketCount
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_getSockets($bForceUpdate = False, $socket = $g__io_mySocket, $whoAmI = $g__io_whoami)

	If $bForceUpdate Then _Io_Loop($socket, $whoAmI)

	Return $g__io_sockets

EndFunc   ;==>_Io_getSockets

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_getMaxConnections
; Description ...:  Server-side only.Returns the maximum allowed connections
; Syntax ........: _Io_getMaxConnections()
; Parameters ....:
; Return values .: integer
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_getMaxConnections()
	Return $g__io_nMaxConnections
EndFunc   ;==>_Io_getMaxConnections

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_getMaxDeadSocketsCount
; Description ...: Returns the maximum dead sockets before an `_Io_TidyUp() ` is triggered
; Syntax ........: _Io_getMaxDeadSocketsCount()
; Parameters ....:
; Return values .: integer
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......: _Io_TidyUp
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_getMaxDeadSocketsCount()
	Return $g__io_max_dead_sockets_count
EndFunc   ;==>_Io_getMaxDeadSocketsCount

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_getBanlist
; Description ...: Server-side only. Returns all / specific banlist entry.
; Syntax ........: _Io_getBanlist([$iEntry = Default])
; Parameters ....: $iEntry              - [optional] an integer value. Default is Default.
; Return values .: Array
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......: _Io_Ban, _Io_Sanction, _Io_IsBanned
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_getBanlist($iEntry = Default)
	If $iEntry == Default Then Return $g__io_aBanlist
	; ip, created_at, expires_at, reason, issued_by
	Local $aRet = [$g__io_aBanlist[$iEntry], $g__io_aBanlist[$iEntry + 1], $g__io_aBanlist[$iEntry + 2], $g__io_aBanlist[$iEntry + 3], $g__io_aBanlist[$iEntry + 4]]
	Return $aRet
EndFunc   ;==>_Io_getBanlist

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_Ban
; Description ...: Server-side only. Ip ban and prevent incomming connections from a given ip.
; Syntax ........: _Io_Ban($socketOrIp[, $nTime = 3600[, $sReason = "Banned"[, $sIssuedBy = "system"]]])
; Parameters ....: $socketOrIp          - a string value.
;                  $nTime               - [optional] a general number value. Default is 3600.
;                  $sReason             - [optional] a string value. Default is "Banned".
;                  $sIssuedBy           - [optional] a string value. Default is "system".
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: $nTime is seconds. Default is therefore 1 hour. A banned client will receive the `banned` event when trying to connect. If you close the server. All bans will persist when you start it up again.
; Related .......: _Io_getBanlist, _Io_Sanction, _Io_IsBanned
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_Ban($socketOrIp, $nTime = 3600, $sReason = "Banned", $sIssuedBy = "system")
	Local Const $created_at = __Io_createTimestamp()
	Local Const $expires_at = $created_at + $nTime
	Local $isSocket = False, $originalSocket = Null

	; Convert sockets to ip
	If StringRegExp($socketOrIp, "^\d+$") Then
		; Save the socket for later use
		$originalSocket = $socketOrIp
		$socketOrIp = _Io_socketGetProperty($socketOrIp, "ip")
		$isSocket = True
	EndIf

	If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_Ban: $socketOrIp = " & $socketOrIp & @LF)

	; Save to memory
	Local $iSlot = $g__io_aBanlist[0]
	$g__io_aBanlist[$iSlot + 1] = $socketOrIp
	$g__io_aBanlist[$iSlot + 2] = $created_at
	$g__io_aBanlist[$iSlot + 3] = $expires_at
	$g__io_aBanlist[$iSlot + 4] = $sReason
	$g__io_aBanlist[$iSlot + 5] = $sIssuedBy
	$g__io_aBanlist[0] = $iSlot + 5

	; If this was a socket, we kick them out
	If $isSocket Then
		_Io_Disconnect($originalSocket)
	EndIf

	Return True

EndFunc   ;==>_Io_Ban

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_Sanction
; Description ...: Server-side only. Remove a previously set ban.
; Syntax ........: _Io_Sanction($socketOrIp)
; Parameters ....: $socketOrIp          - a string value.
; Return values .: Bool. `True` if successfully unbanned. `False` if socket was not found.
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......: _Io_getBanlist, _Io_Ban, _Io_IsBanned
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_Sanction($socketOrIp)
	; Convert sockets to ip
	If StringRegExp($socketOrIp, "^\d+$") Then $socketOrIp = _Io_socketGetProperty($socketOrIp, "ip")

	Local $isBanned = _Io_IsBanned($socketOrIp)

	If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_Sanction: $isBanned = " & ($isBanned ? 'true' : 'false') & @LF)

	; Mask
	If $isBanned > 0 Then
		$g__io_aBanlist[$isBanned] = ""
		$g__io_aBanlist[$isBanned + 1] = ""
		$g__io_aBanlist[$isBanned + 2] = ""
		$g__io_aBanlist[$isBanned + 3] = ""
		$g__io_aBanlist[$isBanned + 4] = ""
		If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_Sanction: return false" & @LF)
		Return True
	EndIf

	If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_Sanction: return true" & @LF)
	Return False
EndFunc   ;==>_Io_Sanction

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_IsBanned
; Description ...: Server-side only. Checks if an socket or ip exists in the banlist
; Syntax ........: _Io_IsBanned($socketOrIp)
; Parameters ....: $socketOrIp          - a string value.
; Return values .: Returns the `$index` of the banned ip if found, returns false if not found.
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: If a `$socket` is passed, the ip will be retrived from the socket.
; Related .......: _Io_getBanlist, _Io_Ban, _Io_Sanction
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_IsBanned($socketOrIp)
	; Convert sockets to ip
	If StringRegExp($socketOrIp, "^\d+$") Then $socketOrIp = _Io_socketGetProperty($socketOrIp, "ip")
	Local Const $now = __Io_createTimestamp()
	Local $isBanned

	If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_IsBanned: $socketOrIp = " & $socketOrIp & @LF)

	; Note the 1 INDex here
	For $i = 1 To $g__io_aBanlist[0] Step +5

		; We cannot return on the first hit since the same ip can be banned multiple times.
		If $g__io_aBanlist[$i] == $socketOrIp Then
			$isBanned = $now < $g__io_aBanlist[$i + 2] ? $i : False
			; only return if banned
			If $isBanned > 0 Then
				If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_IsBanned: $isBanned = true" & @LF)
				Return $isBanned
			EndIf
		EndIf

	Next

	If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_IsBanned: $isBanned = false" & @LF)
	Return False

EndFunc   ;==>_Io_IsBanned

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_ClearEvents
; Description ...: Removes all events from the script.
; Syntax ........: _Io_ClearEvents()
; Parameters ....:
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_ClearEvents()
	If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_ClearEvents: All events cleared" & @LF)
	Global $g__io_events[1001] = [0]
EndFunc   ;==>_Io_ClearEvents

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_TransferSocket
; Description ...: Transfer the socket id and events to a new Socket.
; Syntax ........: _Io_TransferSocket(Byref $from, Const Byref $to)
; Parameters ....: $from                - [in/out] a floating point value.
;                  $to                  - [in/out] a dll struct value.
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......: $from is replaced by $to. So there is no need to do something like this "$to = _Io_TransferSocket($from, $to)"
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_TransferSocket(ByRef $from, Const ByRef $to)

	; Transfer socket events
	For $i = 1 To $g__io_events[0] Step +3
		If $g__io_events[$i + 2] == $from Then $g__io_events[$i + 2] = $to
	Next

	; Transfer main socket identifier
	$from = $to

EndFunc   ;==>_Io_TransferSocket

; #FUNCTION# ====================================================================================================================
; Name ..........: _Io_TidyUp
; Description ...:  Server-side only. Frees some memory by rebuilding arrays and more.
; Syntax ........: _Io_TidyUp()
; Parameters ....:
; Return values .: None
; Author ........: TarreTarreTarre
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Io_TidyUp()

	If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_TidyUp: Start! " & @LF)

	; Store sockets, bans and rooms temporarly.
	Local $aTmpSocket = $g__io_sockets
	Local $aTmpRooms = $g__io_socket_rooms
	Local $aTmpBans = $g__io_aBanlist
	Local $aTmpMiddlewares = $g__io_aMiddlewares

	; Reset everything
	$g__io_sockets[0] = 0
	$g__io_socket_rooms[0] = 0
	$g__io_aBanlist[0] = 0
	$g__io_aMiddlewares[0] = 0
	$g__iBiggestSocketI = 0

	; Rebuild sockets
	For $i = 1 To $aTmpSocket[0] Step +3
		; ignore all dead sockets
		If Not $aTmpSocket[$i] > 0 Then ContinueLoop
		__Io_Push3x($g__io_sockets, $aTmpSocket[$i], $aTmpSocket[$i + 1], $aTmpSocket[$i + 2])

		$g__iBiggestSocketI += 3
	Next

	; Rebuild subscriptions
	For $i = 1 To $aTmpRooms[0] Step +2
		If $aTmpRooms[$i] = Null Then ContinueLoop
		__Io_Push2x($g__io_socket_rooms, $aTmpRooms[$i], $aTmpRooms[$i + 1])
	Next

	; Rebuild banlist
	Local $x = 0
	Local Const $now = __Io_createTimestamp()
	For $i = 1 To $aTmpBans[0] Step +5

		; Keep all active bans
		If $aTmpBans[$i + 2] > $now Then
			$g__io_aBanlist[$x + 1] = $aTmpBans[$i] ; IP
			$g__io_aBanlist[$x + 2] = $aTmpBans[$i + 1] ; Created_at
			$g__io_aBanlist[$x + 3] = $aTmpBans[$i + 2] ; Expires_at
			$g__io_aBanlist[$x + 4] = $aTmpBans[$i + 3] ; Issued_by
			$g__io_aBanlist[$x + 5] = $aTmpBans[$i + 4] ; reason
			$x += 1
		EndIf

	Next
	$g__io_aBanlist[0] = $x

	; Rebuild middlewares
	For $i = 1 To $aTmpMiddlewares[0] Step +3
		If $aTmpMiddlewares[$i] == Null Then ContinueLoop
		__Io_Push($g__io_aMiddlewares, $aTmpMiddlewares[$i])
	Next

	; Reset deathcounter
	$g__io_dead_sockets_count = 0

	If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "_Io_TidyUp: Stop! " & @LF)

EndFunc   ;==>_Io_TidyUp

; ~ Internal functions
Func __Io_makeSocketCollection($sPropToSearchFor, $valueToSearchFor, $propsToReturn, $default = Null, $bArray = True)
	Local $aReturn[1] = [0]
	; Get property from socket
	For $i = 1 To $g__io_sockets[0] Step +3

		; Ignore dead sockets
		If Not $g__io_sockets[$i] > 0 Then ContinueLoop

		Local $searchvalue, $fqdn

		; Determine what we search for
		Switch $sPropToSearchFor
			Case "ip"
				$searchvalue = $g__io_sockets[$i + 1]
			Case "date"
				$searchvalue = $g__io_sockets[$i + 2]
			Case "socket"
				$searchvalue = $g__io_sockets[$i]
			Case Else
				; If we have a custom prop. This is what it should be called
				$fqdn = $g__Io_socketPropertyDomain & "_" & $g__io_sockets[$i] & $sPropToSearchFor

				$searchvalue = IsDeclared($fqdn) ? Eval($fqdn) : $default
		EndSwitch

		; If we struck gold. Make a collection
		If $valueToSearchFor == $searchvalue Then

			Local $valuesToReturn[1] = [0]

			Local $propsToReturnSplitted = StringSplit($propsToReturn, ',')

			; Loop throgu all desired lrops to use
			For $j = 1 To $propsToReturnSplitted[0]
				Local $propToReturn = $propsToReturnSplitted[$j]
				Local $valueToReturn

				Switch $propToReturn
					Case "ip"
						$valueToReturn = $g__io_sockets[$i + 1]
					Case "date"
						$valueToReturn = $g__io_sockets[$i + 2]
					Case "socket"
						$valueToReturn = $g__io_sockets[$i]
					Case Else
						; If we have a custom prop. This is what it should be called
						$fqdn = $g__Io_socketPropertyDomain & "_" & $g__io_sockets[$i] & $propToReturn

						$valueToReturn = IsDeclared($fqdn) ? Eval($fqdn) : $default
				EndSwitch
				__Io_Push($valuesToReturn, $valueToReturn)
			Next

			If $bArray Then
				__Io_Push($aReturn, $valuesToReturn)
			Else
				Return $valuesToReturn
			EndIf

		EndIf


		; Check if we can abort this loop
		If $i >= $g__iBiggestSocketI Then ExitLoop
	Next


	Return $bArray ? $aReturn : SetError(1, 0, $default)
EndFunc   ;==>__Io_makeSocketCollection

Func __Io_FireEvent(Const $socket, ByRef $r_params, Const $sEventName, Const ByRef $parentSocket)

	If $g__io_DevDebug Then
		ConsoleWrite("-" & @TAB & "__Io_FireEvent: attempting to fire event '" & $sEventName & "' with socket " & $socket & " from parentSocket " & $parentSocket & @LF)
	EndIf

	For $i = 1 To $g__io_events[0] Step +3

		If $g__io_events[$i] == $sEventName And $g__io_events[$i + 2] == $parentSocket Then

			Local $fCallbackName = $g__io_events[$i + 1]

			If $g__io_DevDebug Then
				ConsoleWrite("-" & @TAB & "__Io_FireEvent: Event found!" & @LF)
			EndIf

			For $j = 1 To $g__io_aMiddlewares[0]
				Local $mw = $g__io_aMiddlewares[$j]
				Local $mwTargetEvent = $mw[0]
				; +1 is the fucnname() of the callback. Only used for administration
				Local $mwFuncCallback = $mw[2] ;

				If $mwTargetEvent == $sEventName Or $mwTargetEvent == '*' Then

					; IF the middleware returns false. We should not continue this loop and go to next
					If Not $mwFuncCallback($socket, $r_params, $sEventName, $fCallbackName) Then
						If $g__io_DevDebug Then ConsoleWrite("-" & @TAB & "__Io_FireEvent: Middleware '" & $mwTargetEvent & "' returned false. Not firing event. ContinueLoop 2" & @LF)
						ContinueLoop 2
					EndIf
				EndIf
			Next

			__Io_InvokeCallback($socket, $r_params, $fCallbackName)

			Return True
		EndIf
	Next

	If $g__io_DevDebug Then
		ConsoleWrite("-" & @TAB & "__Io_FireEvent: No event found on parentSocket" & @LF)
	EndIf

	Return False

EndFunc   ;==>__Io_FireEvent

Func __Io_InvokeCallback(Const $socket, ByRef $r_params, Const $fCallbackName)


	If Not IsArray($r_params) Then
		Dim $r_params[2] = ['CallArgArray', $socket]
	Else
		$r_params[1] = $socket
	EndIf

	If $g__io_DevDebug Then
		ConsoleWrite("-" & @TAB & "__Io_InvokeCallback: attempting to invoke " & $fCallbackName & " with " & UBound($r_params) - 1 & " parameters. $socket-param included." & @LF)
	EndIf

	Call($fCallbackName, $r_params)

	If @error == 0xDEAD And @extended == 0xBEEF Then

		If $g__io_DevDebug Then
			ConsoleWrite("-" & @TAB & '__Io_InvokeCallback: the callback "' & $fCallbackName & '" failed with DEAD BEEF' & @LF)
		EndIf

		Return False
	EndIf


	If $g__io_DevDebug Then
		ConsoleWrite("-" & @TAB & '__Io_InvokeCallback: Successfully invoked "' & $fCallbackName & '".' & @LF)
	EndIf


	Return True

EndFunc   ;==>__Io_InvokeCallback

Func __Io_createPackage(ByRef $sEventName, ByRef $aParams, $NumParams)
	Local $startParamI = 3

	; Build da package
	Local $sPackage = $sEventName & ($NumParams > 2 ? @LF : "")

	; Determine type of params passed
	If $aParams[0] == 'CallArgArray' Then
		$startParamI = 4
		$NumParams = UBound($aParams) - 2 ; -2 so we ignore  the CallArgArray
	EndIf

	; append parameters
	For $i = $startParamI To $NumParams
		$sPackage &= __Io_data2stringary($aParams[$i - 3]) & ($i < $NumParams ? @LF : "")
	Next

	; Strap
	$sPackage &= "#"

	If $g__io_DevDebug Then
		ConsoleWrite("-" & @TAB & "__Io_createPackage: " & StringReplace($sPackage, @LF, '\n') & @LF)
	EndIf

	; Return Package
	Return $sPackage
EndFunc   ;==>__Io_createPackage

Func __Io_getProductsFromPackage(ByRef $sPackage)
	; Clean package
	$sPackage = StringRegExpReplace($sPackage, "(?s)(.*)\#$", "$1")

	If $g__io_DevDebug Then
		Local $nPackageSize = StringReplace($sPackage, @LF, '\n')
		ConsoleWrite("-" & @TAB & "__Io_getProductsFromPackage(" & StringLen($nPackageSize) & "): " & StringReplace($sPackage, @LF, '\n') & @LF)
	EndIf

	; Split the package(s) into wrapped products
	Local $aWrapped_products = StringSplit($sPackage, "#")

	Local Const $nWrapped_productSize = $aWrapped_products[0]

	Local $aProducts[$nWrapped_productSize + 1] = [0]
	$aProducts[0] = $nWrapped_productSize

	For $i = 1 To $nWrapped_productSize
		Local $sWrapped_product = $aWrapped_products[$i]

		; Split the products into parts
		Local $aWrapped_parts = StringSplit($sWrapped_product, @LF)

		Local $cnWrapped_size = $aWrapped_parts[0] ;

		Local $sEventName = $aWrapped_parts[1]

		; Translate params
		Local $aParams[$cnWrapped_size + 1]
		$aParams[0] = 'CallArgArray' ; This is required, otherwise, Call() will not recognize the array as containing arguments.  ;$cnWrapped_size - 1
		$aParams[1] = '<socket>'

		For $y = 2 To $cnWrapped_size
			$aParams[$y] = __Io_stringary2data($aWrapped_parts[$y])
		Next

		; Create finished product
		Local $aProduct = [$sEventName, $aParams]
		$aProducts[$i] = $aProduct
	Next

	Return $aProducts

EndFunc   ;==>__Io_getProductsFromPackage

Func __Io_handlePackage(Const $socket, ByRef $sPackage, ByRef $parentSocket)
	Local $products = __Io_getProductsFromPackage($sPackage) ;0 event; 1 array of params

	For $w = 1 To $products[0]
		Local $product = $products[$w]

		Local $sEventName = $product[0]
		Local $aParams = $product[1]

		__Io_FireEvent($socket, $aParams, $sEventName, $parentSocket)
	Next

EndFunc   ;==>__Io_handlePackage

Func __Io_data2stringary($sData, $bArrLoop = False)
	Local $VarGetType = VarGetType($sData)

	; Prepare data (If needed
	Switch $VarGetType
		Case 'String'
			$sData = StringToBinary($sData) ;
		Case 'Bool'
			$VarGetType = $sData ? 'Bool:true' : 'Bool:false'
		Case 'Array'
			Local Const $nSize = UBound($sData)
			Local $sRet = ""

			For $i = 0 To $nSize - 1
				$sRet &= StringToBinary(__Io_data2stringary($sData[$i], True)) & ($i < $nSize - 1 ? "|" : "")
			Next

			If $bArrLoop Then
				Return StringToBinary($sRet)
			Else
				$sData = BinaryToString($sRet)
			EndIf
	EndSwitch

	Return StringFormat("%s|%s", $VarGetType, $sData)
EndFunc   ;==>__Io_data2stringary

Func __Io_stringary2data($sDataInput, $bArrLoop = False)

	; Parse nested arrays
	If StringRegExp($sDataInput, "^0x.*") And $bArrLoop Then

		Local $aNestedArr = StringSplit(BinaryToString($sDataInput), "|", 2)
		Local Const $nSize = UBound($aNestedArr) - 1

		For $i = 0 To $nSize
			$aNestedArr[$i] = __Io_stringary2data(BinaryToString($aNestedArr[$i]), True)
		Next

		Return $aNestedArr
	EndIf

	Local $aDataInput = StringRegExp($sDataInput, "([^|]+)\|(.*)", 1)
	If @error Then Return SetError(1, 0, Null)

	Local Const $sType = $aDataInput[0]
	Local Const $uData = $aDataInput[1]

	Switch $sType
		Case "Int32"
			Return Number($uData)
		Case "Int64"
			Return Number($uData)
		Case "Ptr"
			Return Ptr($uData)
		Case "Binary"
			Return Binary($uData)
		Case "Float"
			Return Number($uData)
		Case "Double"
			Return Number($uData)
		Case "Bool:true"
			Return True
		Case "Bool:false"
			Return False
		Case "Keyword"
			Return Null
		Case "Array"
			Local $aArrayChildren = StringSplit($uData, "|", 2)
			Local Const $cnArrayChildrenSize = UBound($aArrayChildren) - 1

			For $i = 0 To $cnArrayChildrenSize
				$aArrayChildren[$i] = __Io_stringary2data(BinaryToString($aArrayChildren[$i]), True)
			Next

			Return $aArrayChildren
		Case "String"
			Return BinaryToString($uData)
		Case Else
			Return "Cannot parse type: " & $sType
	EndSwitch

EndFunc   ;==>__Io_stringary2data

Func __Io_TransportPackage(Const $socket, ByRef $sPackage, Const $bRawPackets = False)
	Local $final_package

	; Check if we should encrypt the data
	If $g__io_vCryptKey Then
		$final_package = _Crypt_EncryptData($sPackage, $g__io_vCryptKey, $g__io_vCryptAlgId)
	ElseIf $bRawPackets == False Then
		$final_package = StringToBinary($sPackage)
	ElseIf $bRawPackets == True Then
		; Do not modify if
	EndIf

	Return TCPSend($socket, $final_package)
EndFunc   ;==>__Io_TransportPackage

Func __Io_RecvPackage(Const $socket, Const $bRawPackets = False)
	Local $package = TCPRecv($socket, 1, 1)
	If @error Then Return SetError(1, 0, Null) ; Connection lost
	If $package == "" Then Return Null

	; Fetch all data from the buffer
	Do
		Local $TCPRecv = TCPRecv($socket, $g__io_nPacketSize, 1)
		$package &= $TCPRecv

		If StringLen($package) >= $g__io_nMaxPacketSize Then Return SetError(2, 0, Null)
	Until $TCPRecv == ""

	; Check if we want to decrypt our data
	If $g__io_vCryptKey Then
		$package = _Crypt_DecryptData($package, $g__io_vCryptKey, $g__io_vCryptAlgId)
	EndIf

	Return Not $bRawPackets ? BinaryToString($package) : $package
EndFunc   ;==>__Io_RecvPackage

Func __Io_createExtendedSocket(ByRef $socket) ;Actual socket, ip address, date
	Local $aExtendedSocket = [$socket, __Io_SocketToIP($socket), StringFormat("%s-%s-%s %s:%s:%s", @YEAR, @MON, @MDAY, @HOUR, @MIN, @SEC)]
	Return $aExtendedSocket
EndFunc   ;==>__Io_createExtendedSocket

Func __Io_Ban_LoadToMemory($sBanlistFile = @ScriptName & ".banlist.ini")
	If Not FileExists($sBanlistFile) Then Return False
	Local Const $now = __Io_createTimestamp()

	Local $aSectionNames = IniReadSectionNames($sBanlistFile)
	If @error Then Return SetError(@error)
	Local $x = 0

	For $i = 1 To $aSectionNames[0]
		Local $aSection = IniReadSection($sBanlistFile, $aSectionNames[$i])

		; Ignore if ban if expired
		If $now > $aSection[3][1] Then ContinueLoop

		$g__io_aBanlist[$x + 1] = $aSection[1][1] ; IP
		$g__io_aBanlist[$x + 2] = $aSection[2][1] ; created_at
		$g__io_aBanlist[$x + 3] = $aSection[3][1] ; expires_at
		$g__io_aBanlist[$x + 4] = $aSection[4][1] ; issued_by
		$g__io_aBanlist[$x + 5] = $aSection[5][1] ; reason

		$x += 5
	Next

	$g__io_aBanlist[0] = $x

	; Remove cache
	If FileExists($sBanlistFile) Then FileDelete($sBanlistFile)

	Return True

EndFunc   ;==>__Io_Ban_LoadToMemory

Func __Io_Ban_SaveToFile($sBanlistFile = @ScriptName & ".banlist.ini")

	; Remove cache
	If FileExists($sBanlistFile) Then FileDelete($sBanlistFile)

	Local $x = 0

	For $i = 1 To $g__io_aBanlist[0] Step +5

		; Ignore sanctioned bans
		If $g__io_aBanlist[$i] <> "" Then
			IniWrite($sBanlistFile, $x, "ip", $g__io_aBanlist[$i])
			IniWrite($sBanlistFile, $x, "created_at", $g__io_aBanlist[$i + 1])
			IniWrite($sBanlistFile, $x, "expires_at", $g__io_aBanlist[$i + 2])
			IniWrite($sBanlistFile, $x, "issued_by", $g__io_aBanlist[$i + 3])
			IniWrite($sBanlistFile, $x, "reason", $g__io_aBanlist[$i + 4])
			$x += 1
		EndIf
	Next

EndFunc   ;==>__Io_Ban_SaveToFile

Func __Io_SocketToIP(Const $socket) ;ty javiwhite
	Local Const $hDLL = "Ws2_32.dll"
	Local $structName = DllStructCreate("short;ushort;uint;char[8]")
	Local $sRet = DllCall($hDLL, "int", "getpeername", "int", $socket, "ptr", DllStructGetPtr($structName), "int*", DllStructGetSize($structName))
	If Not @error Then
		$sRet = DllCall($hDLL, "str", "inet_ntoa", "int", DllStructGetData($structName, 3))
		If Not @error Then Return $sRet[0]
	EndIf
	Return StringFormat("~%s.%s.%s.%s", Random(1, 255, 1), Random(1, 255, 1), Random(0, 10, 1), Random(1, 255, 1)) ;We assume this is a fake socket and just generate a random IP
EndFunc   ;==>__Io_SocketToIP

Func __Io_Init()
	Local Static $firstInit = True

	If $firstInit Then
		; Set default settings for first use
		If Not $g__io_nPacketSize Then _Io_setRecvPackageSize()
		If Not $g__io_nMaxPacketSize Then _Io_setMaxRecvPackageSize()
		If Not $g__io_sOnEventPrefix Then _Io_setOnPrefix()
		$firstInit = False
	EndIf

	If StringRegExp(@AutoItVersion, "^3.3.1\d+\.\d+$") Then
		If Not @Compiled Or $g__io_DevDebug Then
			ConsoleWrite("-" & @TAB & "SocketIO.au3: Because you are using Autoit version " & @AutoItVersion & " Opt('TCPTimeout') has been set to 5. You could manually use another value by putting Opt('TCPTimeout', 5) (once) after _Io_Connect or _Io_listen. Why this is done you could read more about here: https://www.autoitscript.com/trac/autoit/ticket/3575" & @LF)
		EndIf
		Opt('TCPTimeout', 5)
	EndIf

	OnAutoItExitRegister("__Io_Shutdown")
	Return TCPStartup()
EndFunc   ;==>__Io_Init

Func __Io_Shutdown()
	If $g__io_whoami == $_IO_SERVER Then
		__Io_Ban_SaveToFile()
	EndIf
	TCPShutdown()
EndFunc   ;==>__Io_Shutdown

Func __Io_Push(ByRef $a, $v, $bRedim = True)
	If $bRedim Then
		ReDim $a[$a[0] + 2]
	EndIf
	$a[$a[0] + 1] = $v
	$a[0] += 1
	Return $a[0]
EndFunc   ;==>__Io_Push

Func __Io_Push2x(ByRef $a, $v1, $v2)
	$a[$a[0] + 1] = $v1
	$a[$a[0] + 2] = $v2
	$a[0] += 2
	Return $a[0]
EndFunc   ;==>__Io_Push2x

Func __Io_Push3x(ByRef $a, $v1, $v2, $v3)
	$a[$a[0] + 1] = $v1
	$a[$a[0] + 2] = $v2
	$a[$a[0] + 3] = $v3
	$a[0] += 3
	Return $a[0]
EndFunc   ;==>__Io_Push3x

Func __Io_createTimestamp()
	Return (@YEAR * 31556952) + (@MON * 2629746) + (@MDAY * 86400) + (@HOUR * 3600) + (@MIN * 60) + @SEC
EndFunc   ;==>__Io_createTimestamp

Func __Io_createFakeSocket($connectedSocket = Random(100, 999, 1))
	Local $aExtendedSocket = __Io_createExtendedSocket($connectedSocket)
	; Extend socket with some data
	__Io_Push3x($g__io_sockets, $aExtendedSocket[0], $aExtendedSocket[1], $aExtendedSocket[2])
	; Increment our $g__iBiggestSocketI += 3
	$g__iBiggestSocketI += 3
	; return our faked socket
	Return $connectedSocket
EndFunc   ;==>__Io_createFakeSocket

Func __Io_ValidEventName(Const $sEventName)
	Return StringRegExp($sEventName, "^[a-zA-Z 0-9_.:-]+$")
EndFunc   ;==>__Io_ValidEventName
