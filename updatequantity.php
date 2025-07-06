<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Configuration de la base de données
$host = 'localhost';
$dbname = 'easykiv1_phonexa'; // Remplacez par le nom de votre base de données
$username ='easykiv1_phonexa'; // Remplacez par votre nom d'utilisateur
$password =  'kw0aPWVHA~dU';   // Remplacez par votre mot de passe

try {
    // Connexion à la base de données
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Vérifier si la méthode est POST
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['success' => false, 'message' => 'Méthode non autorisée']);
        exit;
    }
    
    // Récupérer les données POST
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Si pas de données JSON, essayer les données POST standard
    if (!$input) {
        $input = $_POST;
    }
    
    // Vérifier les paramètres requis
    if (!isset($input['id_produit']) || !isset($input['quantite'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID produit et quantité requis']);
        exit;
    }
    
    $id_produit = $input['id_produit'];
    $quantite = $input['quantite'];
    
    // Valider les données
    if (!is_numeric($quantite) || $quantite < 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'La quantité doit être un nombre positif']);
        exit;
    }
    
    if (!is_numeric($id_produit) || $id_produit <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID produit invalide']);
        exit;
    }
    
    // Préparer et exécuter la requête de mise à jour
    $stmt = $pdo->prepare("UPDATE produit SET quantite = :quantite WHERE id_produit = :id_produit");
    $stmt->bindParam(':quantite', $quantite, PDO::PARAM_INT);
    $stmt->bindParam(':id_produit', $id_produit, PDO::PARAM_INT);
    
    $result = $stmt->execute();
    
    if ($result) {
        // Vérifier si une ligne a été affectée
        if ($stmt->rowCount() > 0) {
            echo json_encode([
                'success' => true, 
                'message' => 'Quantité mise à jour avec succès',
                'id_produit' => $id_produit,
                'nouvelle_quantite' => $quantite
            ]);
        } else {
            // Aucune ligne mise à jour - le produit n'existe peut-être pas
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Produit non trouvé']);
        }
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour']);
    }
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Erreur de base de données: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Erreur serveur: ' . $e->getMessage()
    ]);
}
?> 