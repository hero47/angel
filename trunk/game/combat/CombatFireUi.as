package angel.game.combat {
	import angel.common.Assert;
	import angel.common.FloorTile;
	import angel.common.Util;
	import angel.game.brain.CombatBrainUiMeld;
	import angel.game.brain.CombatBrainUiMeldPlayer;
	import angel.game.ComplexEntity;
	import angel.game.Icon;
	import angel.game.IRoomUi;
	import angel.game.PieSlice;
	import angel.game.Room;
	import angel.game.RoomExplore;
	import angel.game.RoomInventoryUi;
	import angel.game.Settings;
	import angel.game.ToolTip;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatFireUi implements IRoomUi {
		private var room:Room;
		private var combat:RoomCombat;
		private var player:ComplexEntity;
		private var quickFireWeapon:SingleTargetWeapon;
		private var quickFireWeaponRange:int;
		private var oldFootprintColorTransform:ColorTransform;
		private var aimCursor:Sprite;
		private var aimCursorBitmap:Bitmap;
		
		private var hilightedEnemy:ComplexEntity;
		
		private var clickThisEnemyAgainForQuickFire:ComplexEntity;
		
		private static const LOS_BLOCKED_TILE_HILIGHT_COLOR:uint = 0x000000;
		private static const NO_TARGET_TILE_HILIGHT_COLOR:uint = 0xffffff;
		private static const TARGET_TILE_HILIGHT_COLOR:uint = 0xff0000;
		private static const TARGET_HILIGHT_COLOR:uint = 0xff0000;
		private static const OUT_OF_RANGE_COLOR:uint = 0xc0c0c0;
		public static const COMMIT_INVENTORY_BUTTON_TEXT:String = "Save (costs 2 action points!)"
		
		public function CombatFireUi(room:Room, combat:RoomCombat) {
			this.combat = combat;
			this.room = room;
			aimCursorBitmap = new Bitmap(Icon.bitmapData(Icon.CombatCursorActive));
			aimCursorBitmap.x = -aimCursorBitmap.width / 2;
			aimCursorBitmap.y = -aimCursorBitmap.height / 2;
			aimCursor = new Sprite();
			aimCursor.mouseEnabled = false;
			aimCursor.addChild(aimCursorBitmap);
		}
		
		/* INTERFACE angel.game.IRoomUi */
		
		public function enable(player:ComplexEntity):void {
			trace("entering player fire phase for", player.aaId);
			if (player.actionsRemaining < 1) {
				room.disableUi();
				CombatBrainUiMeld(player.brain).finishedLastFirePhase();
				return;
			}
			this.player = player;
			quickFireWeapon = player.inventory.mainWeapon();
			if ((quickFireWeapon == null) || !quickFireWeapon.readyToFire()) {
				quickFireWeapon = player.inventory.offWeapon();
			}
			quickFireWeaponRange = (quickFireWeapon == null ? 0 : quickFireWeapon.range);
			oldFootprintColorTransform = player.footprint.transform.colorTransform;
			player.footprint.transform.colorTransform = new ColorTransform(0, 0, 0, 1, 0, 255, 0, 0);
			clickThisEnemyAgainForQuickFire = null;
			Mouse.hide();
			room.stage.addChild(aimCursor);
			aimCursor.x = room.mouseX;
			aimCursor.y = room.mouseY;
			adjustActionsRemainingDisplay(true);
		}
		
		public function disable():void {
			if (player != null) {
				trace("ending player fire phase for", player.aaId);
				player.footprint.transform.colorTransform = oldFootprintColorTransform;
				player = null;
			}
			room.moveHilight(null, 0);
			moveTargetHilight(null);
			if (aimCursor.parent != null) {
				room.stage.removeChild(aimCursor);
			}
			Mouse.show();
			adjustActionsRemainingDisplay(false);
		}
		
		public function get currentPlayer():ComplexEntity {
			return player;
		}
		
		public function keyDown(keyCode:uint):void {
			switch (keyCode) {
				case Util.KEYBOARD_C:
					room.changeModeTo(RoomExplore);
				break;
				
				case Util.KEYBOARD_I:
					new RoomInventoryUi(room, player, COMMIT_INVENTORY_BUTTON_TEXT, 2 );
				break;
				
				case Util.KEYBOARD_M:
					combat.augmentedReality.toggleMinimap();
				break;
				
				case Keyboard.ENTER:
					if (clickThisEnemyAgainForQuickFire != null) {
						doPlayerAttack(quickFireWeapon, clickThisEnemyAgainForQuickFire);
					} else {
						doPlayerAttack(null, null);
					}
				break;
				
				case Keyboard.SPACE:
					room.snapToCenter(player.location);
				break;
			}
		}
		
		public function mouseMove(tile:FloorTile):void {
			if (tile != null) {
				var lineOfSight:Boolean = Util.entityHasLineOfSight(player, tile.location);
				if (!lineOfSight) {
					room.moveHilight(tile, LOS_BLOCKED_TILE_HILIGHT_COLOR);
					moveTargetHilight(null);
					ToolTip.removeToolTip();
				} else {
					var enemy:ComplexEntity = room.firstComplexEntityIn(tile.location, filterIsEnemy);
					var outOfRange:Boolean = Util.chessDistance(player.location, tile.location) > quickFireWeaponRange;
					var hilightColor:uint = (outOfRange ? OUT_OF_RANGE_COLOR :
						(enemy == null ? NO_TARGET_TILE_HILIGHT_COLOR : TARGET_TILE_HILIGHT_COLOR));
					room.moveHilight(tile, hilightColor);
					moveTargetHilight(outOfRange ? null : enemy);
					room.updateToolTip(tile.location);
				}
			}
			var global:Point = room.localToGlobal(new Point(room.mouseX, room.mouseY));
			aimCursor.x = global.x;
			aimCursor.y = global.y;
			room.stage.addChild(aimCursor); // keep putting it back on top in case something got added
		}
		
		public function mouseClick(tile:FloorTile):void {
			if ((clickThisEnemyAgainForQuickFire != null) && (tile.location.equals(clickThisEnemyAgainForQuickFire.location))) {
				doPlayerAttack(quickFireWeapon, clickThisEnemyAgainForQuickFire);
			} else if ((quickFireWeaponRange > 0) &&
						(Util.chessDistance(player.location, tile.location) <= quickFireWeaponRange) &&
						Util.entityHasLineOfSight(player, tile.location)) {
				clickThisEnemyAgainForQuickFire = room.firstComplexEntityIn(tile.location, filterIsEnemy);
			} else {
				clickThisEnemyAgainForQuickFire = null;
			}
		}
		
		public function pieMenuForTile(tile:FloorTile):Vector.<PieSlice> {
			var location:Point = tile.location;
			var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
			var lineOfSight:Boolean = Util.entityHasLineOfSight(player, location);
			
			slices.push(new PieSlice(Icon.bitmapData(Icon.CombatPass), "Pass/Reserve Fire", 
						function():void { doPlayerAttack(null, null); }  ));
			addGrenadePieSliceIfLegal(slices, location);
			if (hilightedEnemy != null) {
				Assert.assertTrue(hilightedEnemy.location.equals(location), "Hilighted enemy not on menu tile");
				addFirePieSliceIfLegal(slices, location, player.inventory.mainWeapon(), Icon.CombatFireFirstGun);
				addFirePieSliceIfLegal(slices, location, player.inventory.offWeapon(), Icon.CombatFireSecondGun);
			}
			
			return slices;
		}
	
		
		/************ Private ****************/
		
		private function addFirePieSliceIfLegal(slices:Vector.<PieSlice>, targetLocation:Point, weapon:SingleTargetWeapon, iconClass:Class):void {
			if ((weapon != null) && (weapon.readyToFire()) && (weapon.inRange(player, targetLocation))) {
				slices.push(new PieSlice(Icon.bitmapData(iconClass), "Fire " + weapon.displayName, function():void {
					doPlayerAttack(weapon, hilightedEnemy);
				} ));
			}
		}
		
		private function addGrenadePieSliceIfLegal(slices:Vector.<PieSlice>, targetLocation:Point):void {
			var weapon:Grenade = player.inventory.findFirstMatchingInPileOfStuff(Grenade);
			if ( (weapon != null) &&
						player.inventory.hasFreeHand() &&
						((player.actionsPerTurn == 1) || (player.actionsRemaining >= 2)) &&
						!room.blocksGrenade(targetLocation.x, targetLocation.y) &&
						Util.entityHasLineOfSight(player, targetLocation)) {
				var count:int = player.inventory.countSpecificItemInPileOfStuff(weapon);
				slices.push(new PieSlice(Icon.bitmapData(Icon.CombatGrenade),
					"Throw " + weapon.displayName + " [" + count + " in inventory] at this square",
					function():void { doPlayerAttack(weapon, targetLocation); }
				));
			}
		}
		
		private function constructPieMenu():Vector.<PieSlice> {
			var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
			return slices;
		}
		
		private function doPlayerAttack(weapon:IWeapon, target:Object):void {
			var playerFiring:ComplexEntity = player;
			room.disableUi();
			CombatBrainUiMeld(playerFiring.brain).carryOutAttack(weapon, target);
		}
		
		private function filterIsEnemy(entity:ComplexEntity):Boolean {
			return entity.isEnemyOf(player);
		}
		
		private function moveTargetHilight(target:ComplexEntity):void {
			if (hilightedEnemy != null) {
				hilightedEnemy.filters = [];
			}
			hilightedEnemy = target;
			if (hilightedEnemy != null) {
				var glow:GlowFilter = new GlowFilter(TARGET_HILIGHT_COLOR, 1, 20, 20, 2, 1, false, false);
				hilightedEnemy.filters = [ glow ];
			}
		}
		
		private function adjustActionsRemainingDisplay(show:Boolean = true):void {
			//UNDONE: upgrade stat display to remove this abomination
			combat.augmentedReality.statDisplay.adjustActionsRemainingDisplay(show ? player.actionsRemaining : -1);
		}
	
	} // end class CombatFireUi

}