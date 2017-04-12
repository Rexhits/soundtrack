//
//  EvolutionViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 1/12/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import CoreData

class EvolutionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var playControlBar: UIView!
    let context = appDelegate.persistentContainer.viewContext
    
    @IBOutlet weak var pieceTable: UITableView!
    var pieces = [Piece]()
    var selectedPiece: Piece!
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.gray
        pieceTable.backgroundColor = UIColor.clear
        pieceTable.delegate = self
        pieceTable.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetch()
        self.addChildViewController(appDelegate.playbackController)
        appDelegate.playbackController.view.frame = self.playControlBar.bounds
        self.playControlBar.addSubview(appDelegate.playbackController.view)
        appDelegate.playbackController.didMove(toParentViewController: self)
    }
    
    @IBAction func newPiece(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "gotoTemplateSelect", sender: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !pieces.isEmpty else {
            return 1
        }
        return pieces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = pieceTable.dequeueReusableCell(withIdentifier: "userCreatedPiecesCell", for: indexPath)
        let view = UIView()
        view.backgroundColor = UIColor.orange
        cell.selectedBackgroundView = view
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        guard !pieces.isEmpty else {
            cell.textLabel?.text = "No Piece was Found"
            cell.isUserInteractionEnabled = false
            return cell
        }
        cell.textLabel?.text = pieces[indexPath.row].title
        cell.isUserInteractionEnabled = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let action = UITableViewRowAction(style: .destructive, title: "Delete") { (_, indexPath) in
            let alertController = UIAlertController(title: "Are you sure to delete this piece?", message: nil, preferredStyle: .alert)
            let yes = UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
                self.context.delete(self.pieces[indexPath.row])
                appDelegate.saveContext()
                self.fetch()
                self.pieceTable.reloadData()
            })
            let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alertController.addAction(yes)
            alertController.addAction(cancel)
            self.present(alertController, animated: true, completion: nil)
        }
        return [action]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
        guard !pieces.isEmpty else {
            return
        }
        self.selectedPiece = pieces[indexPath.row]
        self.performSegue(withIdentifier: "gotoPieceEditor", sender: self)
    }
    
    func fetch() {
        do {
            let request = NSFetchRequest<Piece>(entityName: "Piece")
            let result = try context.fetch(request)
            self.pieces = result
        } catch {
            print(error)
        }
        self.pieceTable.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoPieceEditor" {
            let target = segue.destination as! CompositionViewController
            target.piece = self.selectedPiece
        }
    }
    
}
