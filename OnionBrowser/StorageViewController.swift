//
//  StorageViewController.swift
//  OnionBrowser2
//
//  Created by Benjamin Erhart on 11.10.19.
//  Copyright © 2019 jcs. All rights reserved.
//

import UIKit

class StorageViewController: UITableViewController, UISearchResultsUpdating {

	enum DisplayType {
		case cookies
		case localStorage
	}

	private let displayType: DisplayType

    private let searchController = UISearchController(searchResultsController: nil)
    private var filtered = [(key: String, value: Int64)]()

	/**
     true, if a search filter is currently set by the user.
    */
	private var isFiltering: Bool {
        return searchController.isActive
            && !(searchController.searchBar.text?.isEmpty ?? true)
    }

	private var showShortlist = true

	private var cookieJar: CookieJar? {
		return AppDelegate.shared()?.cookieJar
	}

	private lazy var data: [(key: String, value: Int64)] = {
		var data = [String: Int64]()

		if displayType == .cookies {
			if let cookies = cookieJar?.cookieStorage.cookies {
				for cookie in cookies {
					var domain = cookie.domain

					if domain.first == "." {
						domain.removeFirst()
					}

					var counted = data[domain] ?? 0
					data[domain] = counted + 1
				}
			}
		}
		else {
			if let files = cookieJar?.localStorageFiles() {
				for item in files {
					if let filepath = item.key as? String,
						let domain = item.value as? String {

						var space = data[domain] ?? 0

						data[domain] = space + (size(filepath) ?? 0)
					}
				}
			}
		}

		return data.sorted{ $0.value > $1.value }
	}()

	init(type: StorageViewController.DisplayType) {
		displayType = type
		super.init(style: .grouped)
	}

	required init?(coder: NSCoder) {
		displayType = coder.decodeObject(forKey: "displayType") as? DisplayType ?? .cookies
		super.init(coder: coder)
	}

	override func encode(with coder: NSCoder) {
		coder.encode(displayType, forKey: "displayType")
		super.encode(with: coder)
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		navigationItem.title = displayType == .cookies
			? NSLocalizedString("Cookies", comment: "Scene title")
			: NSLocalizedString("Local Storage", comment: "Scene title")

		self.navigationItem.rightBarButtonItem = self.editButtonItem

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
		navigationItem.searchController = searchController
	}


    // MARK: UITableViewDataSource

	override func numberOfSections(in tableView: UITableView) -> Int {
		return isFiltering ? 1 : 2
	}

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return isFiltering ? filtered.count : (showShortlist && data.count > 11 ? 11 : data.count)
		}

		return 1
    }

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if section == 0 {
			return 56
		}

		return super.tableView(tableView, heightForHeaderInSection: section)
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if section == 0 {
			let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
				?? UITableViewHeaderFooterView(reuseIdentifier: "header")

			var title: UILabel? = view.contentView.viewWithTag(666) as? UILabel
			var amount: UILabel? = view.contentView.viewWithTag(667) as? UILabel

			if title == nil {
				title = UILabel()
				title?.textColor = UIColor(red: 0.427451, green: 0.427451, blue: 0.447059, alpha: 1)
				title?.font = .systemFont(ofSize: 14)
				title?.translatesAutoresizingMaskIntoConstraints = false
				title?.tag = 666

				view.contentView.addSubview(title!)
				title?.leadingAnchor.constraint(equalTo: view.contentView.leadingAnchor, constant: 16).isActive = true
				title?.bottomAnchor.constraint(equalTo: view.contentView.bottomAnchor, constant: -8).isActive = true

				amount = UILabel()
				amount?.textColor = title?.textColor
				amount?.font = title?.font
				amount?.translatesAutoresizingMaskIntoConstraints = false
				amount?.tag = 667

				view.contentView.addSubview(amount!)
				amount?.trailingAnchor.constraint(equalTo: view.contentView.trailingAnchor, constant: -16).isActive = true
				amount?.bottomAnchor.constraint(equalTo: view.contentView.bottomAnchor, constant: -8).isActive = true
			}

			var count: Int64 = 0

			for item in isFiltering ? filtered : data {
				count += item.value
			}

			if displayType == .cookies {
				title?.text = NSLocalizedString("Cookies", comment: "Section header")
					.localizedUppercase

				amount?.text = NumberFormatter
					.localizedString(from: NSNumber(value: count), number: .none)
			}
			else {
				title?.text = NSLocalizedString("Local Storage", comment: "Section header")
					.localizedUppercase

				amount?.text = ByteCountFormatter
					.string(fromByteCount: count, countStyle: .file)
			}

			return view
		}

		return nil
	}

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section > 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "button")
				?? UITableViewCell(style: .default, reuseIdentifier: "button")

			cell.textLabel?.text = displayType == .cookies
				? NSLocalizedString("Remove All Cookies", comment: "Button label")
				: NSLocalizedString("Remove All Local Storage", comment: "Button label")

			cell.textLabel?.textAlignment = .center
			cell.textLabel?.textColor = .systemRed

			return cell
		}

		if !isFiltering && showShortlist && indexPath.row == 10 {
			if data.count > 11 {
				let cell = tableView.dequeueReusableCell(withIdentifier: "overflowCell")
					?? UITableViewCell(style: .default, reuseIdentifier: "overflowCell")

				cell.textLabel?.textColor = .systemBlue
				cell.textLabel?.text = NSLocalizedString("Show All Sites", comment: "Button label")

				return cell
			}
		}

        let cell = tableView.dequeueReusableCell(withIdentifier: "storageCell")
			?? UITableViewCell(style: .value1, reuseIdentifier: "storageCell")

		cell.selectionStyle = .none

		let item = (isFiltering ? filtered : data)[indexPath.row]

		cell.textLabel?.text = item.key

		if displayType == .cookies {
			cell.detailTextLabel?.text = NumberFormatter.localizedString(
				from: NSNumber(value: item.value), number: .none)
		}
		else {
			cell.detailTextLabel?.text = ByteCountFormatter.string(
				fromByteCount: item.value, countStyle: .file)
		}

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		if indexPath.section > 0 || !isFiltering && showShortlist && indexPath.row == 10 && data.count > 11 {
			return false
		}

		return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle:
		UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
			let host = (isFiltering ? filtered : data)[indexPath.row].key

			cookieJar?.clearAllData(forHost: host)

			if isFiltering {
				filtered.remove(at: indexPath.row)

				data.removeAll { $0.key == host }
			}
			else {
				data.remove(at: indexPath.row)
			}

			tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
        }
    }


	// MARK: UITableViewDelegate

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		// Must be the show-all cell, others can't be selected.
		if indexPath.section == 0 {
			showShortlist = false
		}
		// The remove-all cell
		else if indexPath.section > 0 {
			cookieJar?.clearAllNonWhitelistedData()

			data.removeAll()
		}

		tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
		tableView.deselectRow(at: indexPath, animated: true)
	}


	// MARK: UISearchResultsUpdating

	func updateSearchResults(for searchController: UISearchController) {
		if let search = searchController.searchBar.text?.lowercased() {
			filtered = data.filter() { $0.key.lowercased().contains(search) }
        }
		else {
			filtered.removeAll()
		}

        tableView.reloadData()
	}


	// MARK: Private Methods

	/**
	Get size in byte of a given file.

	- parameter filepath: The path to the file.
	- returns: File size in bytes.
	*/
	private func size(_ filepath: String?) -> Int64? {
		if let filepath = filepath,
			let attr = try? FileManager.default.attributesOfItem(atPath: filepath) {
			return (attr[.size] as? NSNumber)?.int64Value
		}

		return nil
	}
}
