package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	
	import starling.core.Starling;
	import starling.events.Event;
	
	public class BTConsole extends Sprite
	{
		public function BTConsole()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			var _starling:Starling = new Starling( Game,stage,null,null,"auto","baseline");
			_starling.start();
		}
	}
}