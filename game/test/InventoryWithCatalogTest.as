package angel.game.test {
	import angel.common.WeaponResource;
	import angel.game.combat.SingleTargetWeapon;
	import angel.game.combat.ThrownWeapon;
	import angel.game.inventory.Inventory;
	import angel.game.Settings;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class InventoryWithCatalogTest {
		
		public function InventoryWithCatalogTest() {
			var inventory:Inventory;
			Settings.catalog.retrieveWeaponResource("xxGun1");
			Settings.catalog.retrieveWeaponResource("xxGun2");
			Settings.catalog.retrieveWeaponResource("xxGun3");
			if (Settings.catalog.entry("grenade") == null) {
				var resource:WeaponResource = Settings.catalog.retrieveWeaponResource("grenade");
				resource.type = "thrown";
				resource.weaponClass = ThrownWeapon;
			}
			Autotest.clearAlert();
			
			var invString:String = "0 1 xxGun1,1 1 xxGun2,99 5 grenade";
			inventory = Inventory.fromText(invString);
			Autotest.assertEqual(inventory.mainWeapon().id, "xxGun1");
			Autotest.assertEqual(inventory.offWeapon().id, "xxGun2");
			Autotest.assertEqual(inventory.countInPileOfStuff(ThrownWeapon), 5);
			Autotest.assertEqual(inventory.toText(), invString);
			
			Autotest.assertTrue(inventory.hasByText("xxGun1"));
			Autotest.assertTrue(inventory.hasByText("xxGun2"));
			Autotest.assertFalse(inventory.hasByText("2 xxGun1"));
			Autotest.assertFalse(inventory.hasByText("xxGun3"));
			inventory.addToPileFromText("2 xxGun1");
			Autotest.assertTrue(inventory.hasByText("2 xxGun1"), "Had one, added 2, should have 3 now");
			Autotest.assertTrue(inventory.hasByText("3 xxGun1"));
			Autotest.assertFalse(inventory.hasByText("4 xxGun1"));
			inventory.removeFromAnywhereByText("2 grenade");
			Autotest.assertNoAlert();
			Autotest.assertEqual(inventory.countInPileOfStuff(ThrownWeapon), 3);
			inventory.removeFromAnywhereByText("2 xxGun1");
			Autotest.assertNoAlert();
			Autotest.assertEqual(inventory.mainWeapon(), null);
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 1, "Should have one xxGun1 left");
			inventory.removeFromAnywhereByText("2 xxGun1");
			Autotest.assertAlertText("Remove from inventory: not enough xxGun1.");
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 0, "Should have removed as many as possible");
			
			Autotest.assertEqual(inventory.toText(), "1 1 xxGun2,99 3 grenade");
			
			inventory.removeFromAnywhereByText("2 grenade,xxGun2");
			Autotest.assertEqual(inventory.toText(), "99 1 grenade");
			
			inventory.addToPileFromText("grenade,2 grenade,2 xxGun2");
			Autotest.assertEqual(inventory.countInPileOfStuff(ThrownWeapon), 4);
			var weapon:SingleTargetWeapon = inventory.findFirstMatchingInPileOfStuff(SingleTargetWeapon);
			Autotest.assertEqual(weapon.id, "xxGun2");
			Autotest.assertEqual(inventory.countSpecificItemInPileOfStuff(weapon), 2);
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 2, "The 2 xxGun2 should be the only guns");
			Autotest.assertEqual(inventory.entriesInPileOfStuff(), 2, "Grenades should stack, xxGun2's should stack");
			
			inventory.equipFromPileOfStuff(weapon, Inventory.MAIN_HAND, true);
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 1, "Should have moved one from pile to hand");
			inventory.addToPileFromText("2 xxGun2");
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 3, "Had 1, added 2");
			Autotest.assertEqual(inventory.entriesInPileOfStuff(), 2, "Grenades should stack, xxGun2's should stack");
			inventory.removeFromAnywhereByText("all xxGun2");
			Autotest.assertFalse(inventory.hasByText("xxGun2"), "All should have been removed");
			
		}
		
	}

}