echo "Start install procedure.";

cd frontend;
echo "Install Elm dependencies.";
elm-package install -y;
echo "Build the Elm app.";
elm-make ./src/Main.elm --output=../public/main.js;
cd -;

cd backend;
echo "Install Node dependencies.";
npm install;
echo "Create database.";
echo "Populate database.";
cd -;

echo "--------------------------------"
echo "Installation complete!"
echo "1. Run 'npm start' in the backend directory to run the server."
echo "2. Open the index.html file in the public folder to use the app."
