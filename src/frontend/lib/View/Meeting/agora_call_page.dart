import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraCallPage extends StatefulWidget {
  final String appId;
  final String channelName;
  final String token;
  final int uid;
  final String appointmentId;

  const AgoraCallPage({
    super.key,
    required this.appId,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.appointmentId,
  });

  @override
  State<AgoraCallPage> createState() => _AgoraCallPageState();
}

class _AgoraCallPageState extends State<AgoraCallPage> {
  RtcEngine? _engine;
  bool _engineReady = false;

  bool _isJoined = false;
  bool _micEnabled = true;
  bool _cameraEnabled = false;
  int? _remoteUid;
  bool _remoteVideoMuted = false;
  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    final engine = createAgoraRtcEngine();

    await engine.initialize(RtcEngineContext(appId: widget.appId));

    await engine.enableVideo();
    await engine.enableLocalVideo(false);

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onError: (ErrorCodeType err, String msg) {
          print('❌ AGORA ERROR: $err');
          print('message: $msg');
        },

        onConnectionStateChanged:
            (
              RtcConnection connection,
              ConnectionStateType state,
              ConnectionChangedReasonType reason,
            ) {
              print('🔌 CONNECTION STATE: $state');
              print('reason: $reason');
              print('channel = ${connection.channelId}');
            },
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('✅ LOCAL JOINED');
          print('channel = ${connection.channelId}');
          print('local uid = ${widget.uid}');

          if (!mounted) return;
          setState(() {
            _isJoined = true;
          });
        },

        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('🔥 REMOTE USER JOINED: $remoteUid');
          print('channel = ${connection.channelId}');

          if (!mounted) return;
          setState(() {
            _remoteUid = remoteUid;
          });
        },

        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              print('❌ REMOTE USER LEFT: $remoteUid');
              print('reason = $reason');

              if (!mounted) return;
              setState(() {
                _remoteUid = null;
              });
            },
        onUserMuteVideo: (RtcConnection connection, int uid, bool muted) {
          print('🎥 USER VIDEO MUTED: $uid -> $muted');

          if (!mounted) return;

          setState(() {
            if (uid == _remoteUid) {
              _remoteVideoMuted = muted;
            }
          });
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print('LEFT CHANNEL');

          if (!mounted) return;
          setState(() {
            _isJoined = false;
            _remoteUid = null;
          });
        },
      ),
    );
    print('=== AGORA JOIN REQUEST ===');
    print('appId = ${widget.appId}');
    print('channelName = ${widget.channelName}');
    print('uid = ${widget.uid}');
    print('token = ${widget.token}');
    await engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: widget.uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: false,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );

    if (!mounted) {
      await engine.release();
      return;
    }

    setState(() {
      _engine = engine;
      _engineReady = true;
    });
  }

  Future<void> _leaveCall() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _toggleMic() async {
    if (_engine == null) return;

    _micEnabled = !_micEnabled;
    await _engine!.muteLocalAudioStream(!_micEnabled);

    if (mounted) setState(() {});
  }

  Future<void> _toggleCamera() async {
    if (_engine == null) return;

    _cameraEnabled = !_cameraEnabled;

    if (_cameraEnabled) {
      await _engine!.enableLocalVideo(true);
      await _engine!.startPreview();
      await _engine!.muteLocalVideoStream(false);

      await _engine!.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } else {
      await _engine!.muteLocalVideoStream(true);
      await _engine!.stopPreview();

      await _engine!.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishCameraTrack: false,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      await _engine!.enableLocalVideo(false);
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final engine = _engine;
    _engine = null;

    if (engine != null) {
      engine.leaveChannel();
      engine.release();
    }

    super.dispose();
  }

  Widget _buildVideoViews() {
    if (!_engineReady || _engine == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Positioned.fill(
          child: _remoteUid != null
              ? (_remoteVideoMuted
                    ? Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.videocam_off,
                          color: Colors.white,
                          size: 50,
                        ),
                      )
                    : AgoraVideoView(
                        controller: VideoViewController.remote(
                          rtcEngine: _engine!,
                          canvas: VideoCanvas(uid: _remoteUid),
                          connection: RtcConnection(
                            channelId: widget.channelName,
                          ),
                        ),
                      ))
              : const Center(
                  child: Text(
                    'بانتظار الطرف الآخر...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        ),
        Positioned(
          top: 24,
          right: 16,
          width: 120,
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _cameraEnabled
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade900,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.videocam_off,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: 'mic',
                onPressed: _toggleMic,
                child: Icon(_micEnabled ? Icons.mic : Icons.mic_off),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: 'end',
                backgroundColor: Colors.red,
                onPressed: _leaveCall,
                child: const Icon(Icons.call_end),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: 'camera',
                onPressed: _toggleCamera,
                child: Icon(
                  _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('جلسة الاستشارة'),
        backgroundColor: Colors.black,
      ),
      body: Stack(children: [_buildVideoViews(), _buildControls()]),
    );
  }
}
