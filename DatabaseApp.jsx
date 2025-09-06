import React, { useState, useEffect } from 'react';
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, onSnapshot, addDoc, serverTimestamp, query, orderBy } from 'firebase/firestore';
import { getAuth, signInWithCustomToken, signInAnonymously } from 'firebase/auth';

// Use provided global variables for Firebase configuration
const appId = typeof __app_id !== 'undefined' ? __app_id : 'default-app-id';
const firebaseConfig = JSON.parse(typeof __firebase_config !== 'undefined' ? __firebase_config : '{}');
const initialAuthToken = typeof __initial_auth_token !== 'undefined' ? __initial_auth_token : null;

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

const DatabaseApp = () => {
  const [todos, setTodos] = useState([]);
  const [newTodoText, setNewTodoText] = useState('');
  const [isAuthReady, setIsAuthReady] = useState(false);
  const [userId, setUserId] = useState(null);
  const [error, setError] = useState('');
  
  // A custom modal for displaying messages
  const [modal, setModal] = useState({ visible: false, message: '' });

  const showModal = (message) => {
    setModal({ visible: true, message });
  };

  const hideModal = () => {
    setModal({ visible: false, message: '' });
  };
  
  useEffect(() => {
    // Authenticate the user and set up a state listener
    const authSetup = async () => {
      try {
        if (initialAuthToken) {
          const userCredential = await signInWithCustomToken(auth, initialAuthToken);
          setUserId(userCredential.user.uid);
        } else {
          const userCredential = await signInAnonymously(auth);
          setUserId(userCredential.user.uid);
        }
      } catch (e) {
        console.error('Authentication Error:', e);
        showModal('Error during authentication. Check your Firebase config and rules.');
      }
      setIsAuthReady(true);
    };

    authSetup();
  }, []);

  useEffect(() => {
    // Listen for real-time updates from Firestore
    if (isAuthReady && userId) {
      try {
        // Construct the correct Firestore collection path.
        // Data is stored privately for the user.
        const todosCollectionRef = collection(db, `artifacts/${appId}/users/${userId}/todos`);
        
        // Listen for changes
        const unsubscribe = onSnapshot(todosCollectionRef, (snapshot) => {
          const fetchedTodos = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
          }));
          // Sort the todos by the createdAt timestamp in memory
          fetchedTodos.sort((a, b) => (a.createdAt?.toMillis() || 0) - (b.createdAt?.toMillis() || 0));
          setTodos(fetchedTodos);
        }, (err) => {
          console.error("Firestore onSnapshot error: ", err);
          showModal("Failed to fetch todos. Please check your network connection and security rules.");
        });

        // Cleanup the listener when the component unmounts
        return () => unsubscribe();
      } catch (err) {
        console.error("Firestore setup error: ", err);
        showModal("Failed to set up Firestore listener. Check your collection path.");
      }
    }
  }, [isAuthReady, userId]);

  const addTodo = async (e) => {
    e.preventDefault();
    if (newTodoText.trim() === '') {
      showModal('Please enter a valid to-do item.');
      return;
    }

    if (!userId) {
      showModal('Authentication not ready. Please wait or refresh.');
      return;
    }

    try {
      await addDoc(collection(db, `artifacts/${appId}/users/${userId}/todos`), {
        text: newTodoText,
        createdAt: serverTimestamp(),
      });
      setNewTodoText('');
    } catch (e) {
      console.error('Error adding document:', e);
      showModal(`Error adding todo: ${e.message}`);
    }
  };

  return (
    <div className="bg-gray-900 min-h-screen flex flex-col items-center justify-center p-4 text-white font-sans">
      <div className="bg-gray-800 p-8 rounded-2xl shadow-lg w-full max-w-lg space-y-6 transform transition-all duration-300">
        <h1 className="text-4xl font-extrabold text-center text-indigo-400">
          My To-Do List
        </h1>
        {userId && (
          <div className="text-center text-sm text-gray-400 break-all p-2 bg-gray-700 rounded-lg">
            User ID: {userId}
          </div>
        )}
        <form onSubmit={addTodo} className="flex flex-col sm:flex-row gap-4">
          <input
            type="text"
            value={newTodoText}
            onChange={(e) => setNewTodoText(e.target.value)}
            placeholder="Add a new to-do..."
            className="flex-1 p-3 rounded-xl bg-gray-700 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-colors duration-200"
          />
          <button
            type="submit"
            className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-3 px-6 rounded-xl shadow-md transition-transform transform hover:scale-105 active:scale-95 duration-200"
          >
            Add
          </button>
        </form>

        <ul className="space-y-4 max-h-80 overflow-y-auto pr-2 custom-scrollbar">
          {todos.length > 0 ? (
            todos.map((todo) => (
              <li
                key={todo.id}
                className="bg-gray-700 p-4 rounded-xl flex items-center justify-between shadow-sm"
              >
                <span className="text-gray-200">{todo.text}</span>
              </li>
            ))
          ) : (
            <div className="text-center text-gray-500 italic p-4">
              No todos yet! Add some above.
            </div>
          )}
        </ul>
      </div>

      {modal.visible && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-gray-800 p-6 rounded-xl shadow-xl w-80 text-center">
            <h3 className="text-lg font-semibold mb-4 text-white">Message</h3>
            <p className="text-gray-300 mb-6">{modal.message}</p>
            <button
              onClick={hideModal}
              className="bg-indigo-600 hover:bg-indigo-700 text-white py-2 px-4 rounded-lg transition-colors duration-200"
            >
              OK
            </button>
          </div>
        </div>
      )}
      
      <style jsx global>{`
        .custom-scrollbar::-webkit-scrollbar {
          width: 8px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: #4b5563; /* Tailwind gray-600 */
          border-radius: 10px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background-color: #6366f1; /* Tailwind indigo-500 */
          border-radius: 10px;
          border: 2px solid #4b5563; /* Matches track color */
        }
      `}</style>
    </div>
  );
};

export default DatabaseApp;
