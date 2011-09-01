package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.CharacterStats;
	import angel.common.CharResource;
	import angel.common.Defaults;
	import angel.common.IEntityAnimation;
	import angel.common.MessageCollector;
	import angel.common.Prop;
	import angel.common.Tileset;
	import angel.common.Util;
	import angel.common.WalkerAnimationData;
	import angel.common.WeaponResource;
	import angel.game.brain.CombatBrainNone;
	import angel.game.brain.CombatBrainUiMeldPlayer;
	import angel.game.brain.IBrain;
	import angel.game.brain.UtilBrain;
	import angel.game.combat.ICombatUsable;
	import angel.game.combat.ICombatUseFromPile;
	import angel.game.combat.RoomCombat;
	import angel.game.combat.SingleTargetWeapon;
	import angel.game.combat.ThrownWeapon;
	import angel.game.event.EntityQEvent;
	import angel.game.inventory.Inventory;
	import angel.game.script.TriggerMaster;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormatAlign;

	// A physical object in the game world -- we aren't yet distinguishing between pc/npc/mobile/immobile.
	
	public class ComplexEntity extends SimpleEntity {
		// Facing == rotation/45 if we were in a top-down view.
		// This will make it convenient if we ever want to determine facing from actual angles
		public static const FACE_CAMERA:int = 1;
		
		private static const TEXT_OVER_HEAD_HEIGHT:int = 20;
		
		//NOTE: faction values come from a dropdown in the Room Editor, and are initialized from room files.
		public static const FACTION_ENEMY:int = 0;
		public static const FACTION_FRIEND:int = 1;
		public static const FACTION_NONE:int = 2;
		public static const FACTION_ENEMY2:int = 3;
		
		public static function factionFromName(factionName:String):int {
			switch (factionName) {
				case "enemy":
				default:
					return FACTION_ENEMY;
				case "friend":
					return FACTION_FRIEND;
				case "none":
					return FACTION_NONE;
				case "enemy2":
					return FACTION_ENEMY2;
			}
		}
		
		// Entity stats!
		// CONSIDER: Initial values for some of these come from a CharacterStats. I could have a CharacterStats embedded
		// here rather than individual variables for the ones that overlap, but currently (5/15/11) that's only two.
		protected var myDisplayName:String;
		public var maxHealth:int = 1;
		public var currentHealth:int;
		public var actionsPerTurn:int;
		public var actionsRemaining:int;
		public var hasCoverFrom:Vector.<ComplexEntity> = new Vector.<ComplexEntity>();
		
		public var exploreBrainClass:Class;
		public var exploreBrainParam:String;
		public var combatBrainClass:Class;
		public var combatBrainParam:String;
		public var brain:IBrain;
		public var inventory:Inventory = new Inventory();
		
		private var playerControlled:Boolean;
		public var faction:int;
		
		private var footprint:DisplayObject; // if non-null, drawn on decorations layer centered directly under me
		private var textOverHead:TextField;
		public var controllingOwnText:Boolean; // if true, other things shouldn't monkey with text
		protected var facing:int;
		private var solidnessWhenAlive:uint;
		public var targetable:Boolean = true;
		
		public var movement:EntityMovement;
		private var animation:IEntityAnimation;
		
		public function ComplexEntity(resource:CharResource, id:String = "") {
			super(new Bitmap(resource.standardImage()), resource.solidness, id);
			
			var characterStats:CharacterStats = resource.characterStats;
			maxHealth = currentHealth = characterStats.health;
			actionsPerTurn = characterStats.actionsPerTurn;
			myDisplayName = characterStats.displayName;
			initMovement(characterStats.movePoints, characterStats.maxGait);
			if (characterStats.mainGun != "") {
				inventory.equip(Inventory.makeOne(characterStats.mainGun), Inventory.MAIN_HAND, false);
			}
			if (characterStats.offGun != "") {
				inventory.equip(Inventory.makeOne(characterStats.offGun), Inventory.OFF_HAND, false);
			}
			if (characterStats.inventory != "") {
				inventory.addToPileFromText(characterStats.inventory);
			}
			
			solidness = solidnessWhenAlive = resource.solidness;
			
			facing = FACE_CAMERA;
			animation = new resource.animationData.animationClass(resource.animationData, this.imageBitmap);
		}
		
		public static function createFromRoomContentsXml(charXml:XML, catalog:Catalog, errors:MessageCollector = null):ComplexEntity {
			var id:String;
			
			id = charXml.@id;
			
			var resource:CharResource = catalog.retrieveCharacterResource(id, errors);
			if (resource == null) { // Catalog had something with this id that's not a character resource
				return null;
			}
			
			var entity:ComplexEntity = new ComplexEntity(resource, id);
			entity.setBrain(true, UtilBrain.exploreBrainClassFromString(charXml.@explore), charXml.@exploreParam);
			entity.setBrain(false, UtilBrain.combatBrainClassFromString(charXml.@combat), charXml.@combatParam);
			entity.faction = int(charXml.@faction);
			if (String(charXml.@down) == "yes") {
				entity.initHealth(false);
			}
			entity.setCommonPropertiesFromXml(charXml);
			return entity;
		}
		
		override public function appendXMLSaveInfo(contentsXml:XML):void {
			var xml:XML = <char />;
			addCommonPropertiesToXml(xml);
			if (exploreBrainClass != null) {
				xml.@explore = UtilBrain.brainNameFromClass(true, exploreBrainClass);
				xml.@exploreParam = exploreBrainParam;
			}
			if (combatBrainClass != null) {
				xml.@combat = UtilBrain.brainNameFromClass(false, combatBrainClass);
				xml.@combatParam = combatBrainParam;
			}
			xml.@faction = faction;
			if (!isActive()) {
				xml.@down = "yes";
			}
			contentsXml.appendChild(xml);
		}
		
		override public function cleanup():void {
			if (brain != null) {
				brain.cleanup();
			}
			if (movement != null) {
				movement.cleanup();
			}
			super.cleanup();
		}
		
		override public function set x(value:Number):void {
			super.x = value;
			if (footprint != null) {
				footprint.x = this.x + this.width / 2;
			}
		}
		
		override public function set y(value:Number):void {
			super.y = value;
			if (footprint != null) {
				footprint.y = this.y + Tileset.TILE_HEIGHT / 2;
			}
		}
		
		override public function set visible(value:Boolean):void {
			super.visible = value;
			if (footprint != null) {
				footprint.visible = value;
			}
		}
		
		override public function get displayName():String {
			return myDisplayName;
		}
		
		override public function portraitBitmapData():BitmapData {
			var resource:CharResource = Settings.catalog.retrieveCharacterResource(id);
			return resource.portraitBitmapData;
		}
		
		override public function frobOk(whoFrobbedMe:ComplexEntity):Boolean {
			return Util.chessDistance(whoFrobbedMe.location, myLocation) <= 2;
		}
		
		// If frobbing the entity gives choices, return pie slices for those choices.
		// Otherwise, carry out the frob and return null.
		// NOTE: The frob-ee is passed to the script for reference by "*it".
		override public function frob(whoFrobbedMe:ComplexEntity):Vector.<PieSlice> {
			if (!frobOk(whoFrobbedMe)) {
				//NOTE: currently (5/17/11) shouldn't ever get here -- UI will only call frob if frobOk is true.
				//We may change that, either frob anyway (and get here), or make clicking on a too-far-away object
				//cause the player to attempt to walk up to frobbing distance and then frob. (Complicated, user-friendly
				//for majority cases, but horribly not-what-I-meant!-unfriendly for some cases.)
				Alert.show("Too far away.");
				return null;
			}
			if (isActive()) {
				return super.frob(whoFrobbedMe);
			} else {
				var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
				slices.push(new PieSlice(Icon.bitmapData(Icon.Revive), "Revive", reviveFrob));
				return slices;
			}
		}
		
		public function canMove():Boolean {
			//UNDONE: movement can't be null yet, see note in initMovement
			return ((movement != null) && (movement.maxDistanceForGait() > 0));
			//return (movement != null);
		}
		
		public function moving():Boolean {
			return ((movement != null) && movement.moving());
		}
		
		// CONSIDER: maxGait is a hack, it will probably eventually be based on armor
		public function initMovement(points:int, maxGait:int):void {
			//UNDONE: Currently (5/20/11) we break horribly if movement is null.  Combat phase transition requires
			//getting a EntityEvent.MOVED, which is generated by the movement code.  I'm seriously considering
			//ripping out the current event-driven phase transitions and replacing with a state machine called
			//on enterFrame; if so, I should be able to get rid of that dependency.
			/*
			if (points == 0) {
				if (movement != null) {
					movement.cleanup();
					movement = null;
				}
			} else {
			*/
				if (movement == null) {
					movement = new EntityMovement(this, points, maxGait);
				} else {
					movement.setMovePoints(points);
				}
			/*
			}
			*/
		}
		
		public function attachFootprint(newFootprint:DisplayObject):void {
			if (footprint != null) {
				removeFootprint();
			}
			footprint = newFootprint;
			room.decorationsLayer.addChild(footprint);
			footprint.x = this.x + this.width / 2;
			footprint.y = this.y + Tileset.TILE_HEIGHT/2;
		}
		
		public function removeFootprint():void {
			if (footprint != null) {
				room.decorationsLayer.removeChild(footprint);
				footprint = null;
			}
		}
		
		// returns old ColorTransform
		public function setFootprintColorTransform(transform:ColorTransform):ColorTransform {
			var oldTransform:ColorTransform = footprint.transform.colorTransform;
			footprint.transform.colorTransform = transform;
			return oldTransform;
		}
		
		public function changeFaction(newFaction:int):void {
			faction = newFaction;
			Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.CHANGED_FACTION));
		}
		
		//NOTE: set brain classes and anything they will need for instantiation before calling.
		public function changePlayerControl(willBePc:Boolean, newFaction:int):void {
			if (playerControlled == willBePc) {
				return;
			}
			playerControlled = willBePc;
			if (movement != null) {
				movement.setSpeeds(playerControlled);
			}
			adjustBrainForRoomMode(room.mode);
			if (room.mode != null) {
				room.mode.playerControlChanged(this, playerControlled);
			}
			changeFaction(newFaction);
		}
		
		public function get isPlayerControlled():Boolean {
			return (playerControlled || Settings.controlEnemies);
		}
		
		public function get isReallyPlayer():Boolean {
			return playerControlled;
		}
		
		public function isEnemyOf(entity:ComplexEntity):Boolean {
			if ((faction == FACTION_NONE) || (entity.faction == FACTION_NONE)) {
				return false;
			}
			return (faction != entity.faction);
		}
						
		public function isEnemy():Boolean {
			//CONSIDER: is this true, or will we want to have civilians with combat behavior that are untargetable?
			return (!playerControlled && (combatBrainClass != null) && (currentHealth > 0));
		}
		
		public function isActive():Boolean {
			return (currentHealth > 0);
		}
		
		public function setBrain(forExplore:Boolean, newBrainClass:Class, newParam:String):void {
			if (forExplore) {
				exploreBrainClass = newBrainClass;
				exploreBrainParam = (newBrainClass == null ? null : newParam);
				if ((room != null) && (room.mode is RoomExplore)) {
					adjustBrainForRoomMode(room.mode);
				}
			} else {
				if (Settings.controlEnemies && targetable) {
					// I hope this doesn't break anything...
					combatBrainClass = CombatBrainUiMeldPlayer;
				} else {
					combatBrainClass = (newBrainClass == null ? CombatBrainNone : newBrainClass);
				}
				combatBrainParam = (newBrainClass == null ? null : newParam);
				if ((room != null) && (room.mode is RoomCombat)) {
					adjustBrainForRoomMode(room.mode);
				}
			}
		}
		
		public function adjustBrainForRoomMode(mode:IRoomMode):void {
			if (brain != null) {
				brain.cleanup();
				brain = null;
			}
			if (!isActive()) {
				return;
			}
			
			if (mode is RoomCombat) {
				brain = new combatBrainClass(this, mode, combatBrainParam);
			} else if ((mode is RoomExplore) && (exploreBrainClass != null)) {
				brain = new exploreBrainClass(this, mode, exploreBrainParam);
			}
		}
		
		public function damageDealtSpeedPercent():int {
			return 100 - (movement == null ? 0 : Settings.speedPenalties[movement.mostRecentGait]);
		}
		
		public function damageTakenSpeedPercent():int {
			return 100 - (movement == null ? 0 : Settings.speedDefenses[movement.mostRecentGait]);
		}
		
		//NOTE: also used for healing by passing negative damage
		public function takeDamage(baseDamage:int, speedReducesDamage:Boolean, coverDamageReductionPercent:int = 0):void {
			if (speedReducesDamage) {
				baseDamage = baseDamage * damageTakenSpeedPercent() / 100;
			}
			if (coverDamageReductionPercent > 0) {
				baseDamage = baseDamage * (100 - coverDamageReductionPercent) / 100;
			}
			currentHealth -= baseDamage;
			if (currentHealth > maxHealth) {
				currentHealth = maxHealth;
			}
			trace(aaId, "damaged for", baseDamage, ", health now", currentHealth);
			if (!controllingOwnText) {
				setTextOverHead(String(currentHealth));
			}
			if (currentHealth > 0) {
				Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.HEALTH_CHANGE));
			} else {
				solidness ^= Prop.TALL; // Dead entities are short, by fiat.
				if (!controllingOwnText) {
					setTextOverHead(null);
				}
				startDeathAnimation();
				Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.DEATH));
			}
		}
		
		// Reset health at start and end of combat.
		public function initHealth(active:Boolean):void {
			if (active) {
				currentHealth = maxHealth;
				standUp();
			} else {
				currentHealth = 0;
				animation.turnToFacing(WalkerAnimationData.FACE_DYING, 0); // stands back up if we were dead
				solidness = solidness & (~Prop.TALL); // Dead entities are short, by fiat.
				Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.CHANGED_SOLIDNESS));
			}
		}
		
		public function huddle():void {
			solidness = solidness & (~Prop.TALL); 
			Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.CHANGED_SOLIDNESS));
			animation.startHuddleAnimation();
		}
		
		public function standUp():void {
			animation.turnToFacing(facing, 0); // stands back up if we were down
			solidness = solidnessWhenAlive;
			Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.CHANGED_SOLIDNESS));
		}
		
		public function revive():void {
			var wasActive:Boolean = isActive();
			initHealth(true);
			if (!wasActive) {
				adjustBrainForRoomMode(room.mode);
			}
			Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.REVIVE));
		}
		
		public function reviveFrob():void {
			if ((triggers != null) && triggers.hasScriptFor(TriggerMaster.ON_REVIVE_FROB)) {
				Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.REVIVE_FROB));
			} else {
				revive();
			}
		}
		
		public function setTextOverHead(value:String, color:uint = 0xffffff):void {
			if ((value == null) && (textOverHead != null)) {
				textOverHead.visible = false;
			} else if (value != null) {
				if (textOverHead == null) {
					textOverHead = Util.textBox("", Prop.WIDTH, TEXT_OVER_HEAD_HEIGHT, TextFormatAlign.CENTER);
					textOverHead.background = true;
					textOverHead.autoSize = TextFieldAutoSize.CENTER;
					textOverHead.y = imageBitmap.y - TEXT_OVER_HEAD_HEIGHT - 2;
					addChild(textOverHead);
				}
				textOverHead.visible = true;
				textOverHead.text = value;
				textOverHead.backgroundColor = color;
			}
		}
				
		public function startDeathAnimation():void {
			animation.startDeathAnimation();
		}
		
		public function adjustImageForMove(frameOfMove:int, totalFramesInMove:int, gait:int):void {
			animation.adjustImageForMove(facing, frameOfMove, totalFramesInMove, gait);
		}
		
		public function currentFacing():int {
			return facing;
		}
		
		public function turnToFacing(newFacing:int, newGait:int):void {
			facing = Util.negSafeMod(newFacing, 8);
			animation.turnToFacing(facing, newGait);
		}
		
		// Return the facing that closest approximates the tile's direction
		public function findFacingToTile(loc:Point):int {
			// The +360 ensures that angle / 45 will round the direction we want even if original angle was negative
			var angle:int = Util.findRotFacingVector(loc.subtract(myLocation)) + 360 + 22;
			return ((angle / 45) % 8);
		}
		
		// Turn to the facing that closest approximates the tile's direction
		public function turnToFaceTile(loc:Point):void {
			var gait:int = (movement == null ? 0 : movement.mostRecentGait);
			turnToFacing(findFacingToTile(loc), gait);
		}
		
		public function centerRoomOnMe():void {
			room.x = (stage.stageWidth / 2) - this.x - this.width/2;
			room.y = (stage.stageHeight / 2) - this.y - this.height/2;
		}
		
		// If we're talking real world, this makes no sense -- cover would be directional, and we'd have to talk about
		// cover from a particular enemy.  Wm wants this move-to-shoot-from-cover thing to be available whenever you're
		// next to a "tall" blocker, regardless of whether there are even any enemies around at all, so...
		public function hasCover():Boolean {
			for each (var toNeighbor:Point in Pathfinder.neighborCheck) {
				var xNext:int = toNeighbor.x + myLocation.x;
				var yNext:int = toNeighbor.y + myLocation.y;
				var neighbor:Point = myLocation.add(toNeighbor);
				if ((xNext >= 0) && (xNext < room.size.x) && (yNext >= 0) && (yNext < room.size.y) && 
							room.blocksSight(xNext, yNext)) {
					return true;
				}
			}
			return false;
		}
		
		private function hasAUsableEquippedWeapon():Boolean {
			var combat:RoomCombat = room.mode as RoomCombat;
			if (combat == null) {
				return false;
			}
			return ( ((inventory.mainWeapon() != null) && (inventory.mainWeapon().readyToFire(combat))) ||
					 ((inventory.offWeapon() != null)  && (inventory.offWeapon().readyToFire(combat))) );
		}
		
		//CONSIDER: maybe we shouldn't even check this -- even if they have no usable they could still manipulate inventory?
		public function hasAUsableItem():Boolean {
			return (hasAUsableEquippedWeapon() ||
					 (inventory.findFirstMatchingInPileOfStuff(ICombatUseFromPile) != null));
		}
		
		public function hasAUsableItemAndEnoughActions():Boolean {
			return ((hasAUsableEquippedWeapon() && (actionsRemaining > 0)) ||
					 ((inventory.findFirstMatchingInPileOfStuff(ICombatUseFromPile) != null) && (actionsRemaining > 1)));
		}
		
	} // end class ComplexEntity

}
