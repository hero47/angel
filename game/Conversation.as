package angel.game {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	 // When added to stage, conversation disables the room ui and sets up its own.
	 // When conversation is finished, it removes itself and restores the room's previous ui, without the room doing anything.
	 
	 // This current (4/18/11) conversation is largely a stub; eventually it will get text in some data-driven fashion
	 // and things will happen as a result of user choices in the conversation.  Wm hasn't given me any clues yet as
	 // to how any of this is expected to work, which makes me nervous about the whole thing. ;)
	 
	public class Conversation extends Sprite {
		
		// Temporary -- eventually these will come from catalog I believe
		// size 276 x 329 ???
		[Embed(source = '../../../EmbeddedAssets/conversation_NPC_portrait.png')]
		private static const NpcPortrait:Class;
		[Embed(source = '../../../EmbeddedAssets/conversation_MC_portrait.png')]
		private static const PcPortrait:Class;
		
		private static const TARGET_HILIGHT_COLOR:uint = 0x0000ff;
		
		private var npcBox:ConversationBox;
		private var pcBox:ConversationBox;
		private var target:SimpleEntity;
		
		public function Conversation(target:SimpleEntity) {
			this.target = target;
			var glow:GlowFilter = new GlowFilter(TARGET_HILIGHT_COLOR, 1, 20, 20, 2, 1, false, false);
			target.filters = [ glow ];
			target.room.snapToCenter(target.location);
			
			npcBox = new ConversationBox(new NpcPortrait(), false);
			addChild(npcBox);
			npcBox.x = 500;
			npcBox.y = 100;
			npcBox.addEventListener(Event.COMPLETE, npcBoxComplete);
			
			// Placeholder text, obviously
			npcBox.text = "My prime function is as a information utility.\nI would be more than happy to answer any questions you have, officer.";
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
			
		}
		
		private function addedToStageListener(event:Event):void {
			target.room.disableUi();
		}
		
		private function npcBoxComplete(event:Event):void {
			npcBox.removeEventListener(Event.COMPLETE, npcBoxComplete);
			pcBox = new ConversationBox(new PcPortrait(), true);
			addChild(pcBox);
			pcBox.x = 500;
			pcBox.y = 300;
			pcBox.addEventListener(Event.COMPLETE, pcBoxComplete);
			
			pcBox.text = "I do have a lot of questions, actually--there’s a lot here that just doesn’t add up, and I hope you can help me make sense of it."		
		}
		
		private function pcBoxComplete(event:Event):void {
			pcBox.removeEventListener(Event.COMPLETE, pcBoxComplete);
			stage.removeChild(this);
			target.filters = [];
			target.room.restoreLastUi();
		}
		
	}

}