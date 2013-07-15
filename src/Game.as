package
{
	import com.as3breeze.air.ane.android.*;
	import com.as3breeze.air.ane.android.events.*;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Label;
	import feathers.controls.ScreenNavigator;
	import feathers.controls.ScreenNavigatorItem;
	import feathers.controls.TextInput;
	import feathers.motion.transitions.ScreenSlidingStackTransitionManager;
	import feathers.themes.MinimalMobileTheme;
	
	import flash.utils.ByteArray;
	
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.text.TextField;
	import starling.utils.HAlign;
	import starling.utils.VAlign;
	
	public class Game extends Sprite
	{
		protected const ALFA_ADDRESS:String = "AAAAAA";
		protected const BRAVO_ADDRESS:String = "BBBBBBB";
		protected const INSECURE_UUID:String = "029F9140-EBC6-11E2-91E2-0800200C9A66";
		protected const SECURE_UUID:String = "AA25E520-EBBE-11E2-91E2-0800200C9A66";
		
		protected var bluetooth:Bluetooth;
		protected var remoteAddress:String;
		protected var remoteDevice:BluetoothDevice;
		
		protected var inputField:TextInput;
		protected var sendButton:Button;
		protected var logField:TextField;
		
		protected var createSessionButton:Button;
		protected var joinSessionButton:Button;
		
		public function Game()
		{
			super();
			var theme:MinimalMobileTheme = new MinimalMobileTheme( stage );
						
			addEventListener( Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event):void{
			
			if(Bluetooth.isSupported()){
				trace('BT is supported');
				
				bluetooth = Bluetooth.currentAdapter( INSECURE_UUID, SECURE_UUID );
				bluetooth.addEventListener( BluetoothEvent.BLUETOOTH_ANE_INITIALIZED, onBluetoothInit );
			}
			
		}
		
		protected function onBluetoothInit(event:BluetoothEvent):void{
			trace("I'm "+bluetooth.localDeviceName);
			
			createSessionButton = new Button();
			createSessionButton.width = 400;
			createSessionButton.label = "Iniciar Sesión";
			createSessionButton.x = (this.stage.stageWidth - createSessionButton.width) / 2;
			createSessionButton.y = 300;
			addChild(createSessionButton);
			
			joinSessionButton = new Button();
			joinSessionButton.width = 400;
			joinSessionButton.label = "Unirse a Sesión";
			joinSessionButton.x = (this.stage.stageWidth - joinSessionButton.width) / 2;
			joinSessionButton.y = 450;
			addChild(joinSessionButton);
			
			createSessionButton.addEventListener( Event.TRIGGERED, setupForServer );
			joinSessionButton.addEventListener( Event.TRIGGERED, setupForClient );
		}
		
		protected function setupConectionScreen():void{
			removeChild(createSessionButton);
			removeChild(joinSessionButton);
			
			logField = new TextField(1280, 600, '');
			logField.hAlign = HAlign.LEFT;
			addChild(logField);
			
			sendButton = new Button();
			sendButton.width = 100;
			sendButton.height = 30;
			sendButton.label = "Send";
			sendButton.x = this.stage.stageWidth-100;
			sendButton.y = this.stage.stageHeight-30;
			sendButton.addEventListener(Event.TRIGGERED, sendText);
			addChild(sendButton);
			
			inputField = new TextInput();
			inputField.width = this.stage.stageWidth-100;
			inputField.height = 30;
			inputField.y = this.stage.stageHeight-30;
			addChild(inputField);
		}
		
		protected function setupForServer(event:Event):void{
			trace('setup for server');
			bluetooth.serverMode = true;
			bluetooth.addEventListener(BluetoothDeviceEvent.BLUETOOTH_DEVICE_CONNECTED, deviceEventHandler);
			setupConectionScreen();
			logField.text = "-- console for server --";
		}
		
		protected function setupForClient(event:Event):void{
			trace('setup for client');
			
			//CLIENT / CONNECTS TO 
			var pairedDevices:Vector.<BluetoothDevice> = bluetooth.getPairedDevices();
			var btDevice:BluetoothDevice;
			
			pairedDevices.forEach( 
				function( device:BluetoothDevice, index:int, vector:Vector.<BluetoothDevice> ){ 
					if( device.address == ALFA_ADDRESS || device.address == BRAVO_ADDRESS ) 
						btDevice = device;
				} ); 
			
			btDevice.addEventListener( BluetoothDeviceEvent.BLUETOOTH_DEVICE_CONNECTED, deviceEventHandler); 
			btDevice.addEventListener( BluetoothDeviceEvent.BLUETOOTH_DEVICE_DISCONNECTED, deviceEventHandler); 
			btDevice.addEventListener( BluetoothDeviceEvent.BLUETOOTH_DEVICE_CONNECT_ERROR, deviceEventHandler);
			
			trace("trying to connect");
			//btDevice.connect();
			if(bluetooth.localDeviceAddress == ALFA_ADDRESS){
				bluetooth.connect(BRAVO_ADDRESS);
			}else if(bluetooth.localDeviceAddress == BRAVO_ADDRESS){
				bluetooth.connect(ALFA_ADDRESS);
			}
			
			setupConectionScreen();
			logField.text = "-- console for client --";
		}
		
		protected function sendText(event:Event):void{
			if(remoteDevice != null){
				var ba:ByteArray = new ByteArray(); 
				ba.writeUTFBytes( inputField.text ); 
				ba.position = 0;  
				remoteDevice.sendData(ba);	
			}
			logField.text += '\n Yo: '+inputField.text;
			inputField.text = '';
		}
		
		protected function deviceEventHandler( b:BluetoothDeviceEvent ):void 
		{ 
			switch( b.type ) { 
				case BluetoothDeviceEvent.BLUETOOTH_DEVICE_CONNECTED: 
					trace( "Connected to:", b.device.name );
					remoteDevice = b.device;
					
					trace('local UUID: '+bluetooth.secureUUID);
					trace('remote UUID: '+remoteDevice.UUID);
					
					remoteDevice.addEventListener( BluetoothDataEvent.BLUETOOTH_RECEIVE_DATA, gotData );
					remoteDevice.addEventListener( BluetoothDataEvent.BLUETOOTH_SEND_BYTEARRAY_READ_ERROR, byteArrayError);
					remoteDevice.addEventListener( BluetoothDataEvent.BLUETOOTH_SEND_ERROR, sendError);
					remoteDevice.addEventListener( BluetoothDataEvent.BLUETOOTH_SEND_SUCCESS, sendSuccess);
					
					trace("Send data");
					// Create ByteArray of what is being sent. 
					var ba:ByteArray = new ByteArray(); 
					ba.writeUTFBytes( bluetooth.localDeviceName + ' says hello to you' );  
					ba.position = 0;
					trace('byte array to send');
					trace(ba);
					b.device.sendData(ba);
					
					break; 
				case BluetoothDeviceEvent.BLUETOOTH_DEVICE_DISCONNECTED: 
					trace( "Device is dis-connected!" );
					break; 
				case BluetoothDeviceEvent.BLUETOOTH_DEVICE_CONNECT_ERROR:
					trace( "Some error occured when connecting :(" );
					break;
			}
		}
		
		private function sendError(event:BluetoothDataEvent):void{
			trace('sendError');
			logField.text += '\n sendError';
		}
		
		private function sendSuccess(event:BluetoothDataEvent):void{
			trace('sendSuccess');
			logField.text += '\n sendSuccess';
		}
		
		private function byteArrayError(event:BluetoothDataEvent):void{
			trace('byteArrayError');
			logField.text += '\n byteArrayError';
		}
		
		private function gotData( b:BluetoothDataEvent ):void 
		{ 
			trace(b.error);
			trace(b.data);
			trace(b.message);
			
			var ba:ByteArray = b.data as ByteArray;
			ba.position = 0;
			var str:String = ba.readUTFBytes( ba.bytesAvailable ) as String;
			trace("Received from bluetooth device: ",str);
			logField.text += '\n' + remoteDevice.name + ': '+ str; 
		}
	}
}