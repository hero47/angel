package angel.game.script {
	import angel.game.combat.RoomCombat;
	import angel.game.event.QEvent;
	import angel.game.Room;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import flash.display.Bitmap;
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
	 
	public class ConversationInterface extends Sprite {
		
		// Temporary -- eventually these will come from catalog I believe
		// size 276 x 329 ???
		[Embed(source = '../../EmbeddedAssets/conversation_NPC_portrait.png')]
		private static const NpcPortrait:Class;
		[Embed(source = '../../EmbeddedAssets/conversation_MC_portrait.png')]
		private static const PcPortrait:Class;
		
		private static const TARGET_HILIGHT_COLOR:uint = 0x0000ff;
		
		private var npcBox:ConversationBox;
		private var pcBox:ConversationBox;
		private var target:SimpleEntity;
		private var conversationData:ConversationData;
		private var room:Room;
		
		//UNDONE: investigate: merge this with script's?
		public var context:ScriptContext;
		
		public function ConversationInterface(target:SimpleEntity, conversationData:ConversationData) {
			this.target = target;
			this.room = target.room;
			this.conversationData = conversationData;
			var glow:GlowFilter = new GlowFilter(TARGET_HILIGHT_COLOR, 1, 20, 20, 2, 1, false, false);
			target.filters = [ glow ];
			room.snapToCenter(target.location);
			addEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
		}	
		
		private function addedToStageListener(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
			room.pauseGameTimeIndefinitely(this);
			room.disableUi();
			context = new ScriptContext(room, target);
			conversationData.runConversation(this);
		}
		
		public function startEntry(npcSegment:ConversationSegment, pcSegments:Vector.<ConversationSegment>):void {
			var havePcSegments:Boolean = pcSegments.length > 0;
			
			if (npcSegment != null) {
				npcBox = displayConversationSegment(new NpcPortrait(), false, Vector.<ConversationSegment>([npcSegment]),
						500, 100, (havePcSegments ? null : entryFinishedListener));	
			}
			
			if (havePcSegments) {
				pcBox = displayConversationSegment(new PcPortrait(), true, pcSegments, 500, 300, entryFinishedListener);				
			}
			
		}
		
		private function displayConversationSegment(portraitBitmap:Bitmap, pc:Boolean, segments:Vector.<ConversationSegment>, x:int, y:int, listener:Function):ConversationBox {
			var box:ConversationBox = new ConversationBox(portraitBitmap, pc, segments, listener != null);
			addChild(box);
			box.x = x;
			box.y = y;
			if (listener != null) {
				Settings.gameEventQueue.addListener(this, box, ConversationBox.CONVERSATION_ENTRY_FINISHED, listener);
			}
			return box;
		}
		
		private function entryFinishedListener(event:QEvent):void {
			Settings.gameEventQueue.removeListener(event.source, ConversationBox.CONVERSATION_ENTRY_FINISHED, entryFinishedListener);
			
			if (pcBox != null) {
				removeChild(pcBox);
				pcBox = null;
			}
			if (npcBox != null) {
				removeChild(npcBox);
				npcBox = null;
			}
		}
		
		public function cleanup():void {
			if (this.parent != null) {
				parent.removeChild(this);
			}
			target.filters = [];
			room.unpauseFromLastIndefinitePause(this);
			room.restoreUiAfterConversation();
			
			context.endOfScriptActions();
			
			if (room.mode is RoomCombat) {
				RoomCombat(room.mode).checkForCombatOver();
			}
		}
		
	}

}